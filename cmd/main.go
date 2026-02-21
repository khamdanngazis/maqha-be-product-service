// cmd/main.go

package main

import (
	"flag"
	"fmt"
	"log"
	"maqhaa/library/logging"
	"maqhaa/library/middleware"
	exRepo "maqhaa/product_service/external/repository"
	"maqhaa/product_service/internal/app/repository"
	"maqhaa/product_service/internal/app/service"
	"maqhaa/product_service/internal/config"
	"maqhaa/product_service/internal/database"
	grpcHandler "maqhaa/product_service/internal/interface/grpc/handler"
	pb "maqhaa/product_service/internal/interface/grpc/model"
	httpHandler "maqhaa/product_service/internal/interface/http/handler"
	"maqhaa/product_service/internal/interface/http/router"
	"net"
	"net/http"
	"os"
	"strings"
	"time"

	"google.golang.org/grpc"
	"github.com/soheilhy/cmux"
)

func main() {
	// Define a command line flag for the config file path
	configFilePath := flag.String("config", "config/config.yaml", "path to the config file")
	logFile := flag.String("log.file", "../logs", "Logging file")

	flag.Parse()

	initLogging(*logFile)

	// Load the configuration
	cfg, err := config.LoadConfig(*configFilePath)
	if err != nil {
		logging.Log.Fatalf("Error loading configuration: %v", err)
	}
	logging.Log.Infof("Load configuration from %v", *configFilePath)
	// Access configuration values
	dbConfig := cfg.Database

	db, err := database.NewDB(&dbConfig)
	if err != nil {
		logging.Log.Fatalf("Error loading configuration: %v", err)
	}

	// Close the database connection when done
	sqlDB, err := db.DB()
	if err != nil {
		logging.Log.Fatalf("Error getting DB connection: %v", err)
	}
	defer sqlDB.Close()

	// Initialize handlers
	httpRouter := router.NewMuxRouter()

	pingHandler := httpHandler.NewPingHandler()
	httpRouter.GET("/ping", pingHandler.Ping)

	// Initialize product service
	userRepository := exRepo.NewUserRepository(cfg.ExternalConnection.AuthService.Host)
	imageRepository := repository.NewImagesRepository(cfg.ImagePath)
	productRepository := repository.NewProductRepository(db)
	productService := service.NewProductService(productRepository, userRepository, imageRepository)
	productHandler := httpHandler.NewProductHandler(productService)

	httpRouter.GET("/product", productHandler.GetProductGroupsByCategoryHandler)
	httpRouter.POST("/product", productHandler.AddProductHandler)
	httpRouter.PUT("/product", productHandler.EditProductHandler)
	httpRouter.DELETE("/product", productHandler.DeactiveProductHandler)
	httpRouter.POST("/category", productHandler.AddCategoryHandler)
	httpRouter.PUT("/category", productHandler.EditCategoryHandler)
	httpRouter.DELETE("/category", productHandler.DeactiveCategoryHandler)

	productHandlerGrpc := grpcHandler.NewProductGRPCHandler(productService)
	// Initialize gRPC server
	grpcServer := grpc.NewServer(grpc.UnaryInterceptor(middleware.LoggingInterceptor))

	// Register gRPC service implementation
	pb.RegisterProductServer(grpcServer, productHandlerGrpc)

	// Create a TCP listener on the app port for both HTTP and gRPC
	listener, err := net.Listen("tcp", cfg.AppPort)
	if err != nil {
		logging.Log.Fatalf("Error creating listener: %v", err)
	}
	defer listener.Close()

	// Create a connection multiplexer
	mux := cmux.New(listener)

	// Match connections based on protocol
	grpcListener := mux.MatchWithWriters(cmux.HTTP2MatchHeaderFieldSendSettings("content-type", "application/grpc"))
	httpListener := mux.Match(cmux.HTTP1Fast())

	// Start gRPC server on gRPC listener
	go func() {
		logging.Log.Infof("gRPC server listening on %s", cfg.AppPort)
		if err := grpcServer.Serve(grpcListener); err != nil {
			logging.Log.Errorf("gRPC server error: %v", err)
		}
	}()

	// Start HTTP server on HTTP listener
	go func() {
		httpServer := &http.Server{
			Handler: httpRouter.Handler(),
		}
		logging.Log.Infof("HTTP server listening on %s", cfg.AppPort)
		if err := httpServer.Serve(httpListener); err != nil && err != http.ErrServerClosed {
			logging.Log.Errorf("HTTP server error: %v", err)
		}
	}()

	// Start the multiplexer
	logging.Log.Infof("Starting dual-protocol server (HTTP + gRPC) on %s", cfg.AppPort)
	if err := mux.Serve(); err != nil {
		logging.Log.Fatalf("Server error: %v", err)
	}
}

func initLogging(logFolder string) {
	logging.InitLogger()

	if strings.EqualFold(os.Getenv("PRODUCT_LOG_TO_STDOUT"), "true") {
		logging.Log.SetOutput(os.Stdout)
		return
	}
	currentDate := time.Now().Format("2006-01-02")

	// Specify the log file with the current date
	logFilePath := fmt.Sprintf("%s/app_%s.log", logFolder, currentDate)

	// Create the log file if it doesn't exist
	logFile, err := os.OpenFile(logFilePath, os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0600)
	if err != nil {
		log.Fatal("Error creating log file:", err)
	}

	// Set the logrus output to the log file
	logging.Log.SetOutput(logFile)

	go func() {
		for {
			time.Sleep(time.Hour) // Adjust the sleep duration as needed
			newDate := time.Now().Format("2006-01-02")
			if newDate != currentDate {
				currentDate = newDate
				logFilePath = fmt.Sprintf("%s/app_%s.log", logFolder, currentDate)
				newLogFile, err := os.OpenFile(logFilePath, os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0600)
				if err != nil {
					logging.Log.Fatal("Error creating log file:", err)
				}
				logFile = newLogFile
				logging.Log.SetOutput(logFile)
			}
		}
	}()
}
