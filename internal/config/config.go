// internal/config/config.go

package config

import (
	"fmt"
	"strings"

	"github.com/spf13/viper"
)

// DatabaseConfig holds the database configuration.
type DatabaseConfig struct {
	Host     string
	Port     int
	User     string
	Password string
	DBName   string
	Debug    bool
}

// AuthServiceConfig holds the auth service configuration.
type AuthServiceConfig struct {
	Host string
}

// ExternalConnectionConfig holds external service configurations.
type ExternalConnectionConfig struct {
	AuthService AuthServiceConfig
}

// Config holds the application configuration.
type Config struct {
	Database           DatabaseConfig
	ExternalConnection ExternalConnectionConfig
	AppPort            string
	GrpcPort           string
	ImagePath          string
}

// LoadConfig loads configuration from a specified file path, environment variables, and/or config files.
func LoadConfig(filePath string) (*Config, error) {
	if filePath != "" {
		viper.SetConfigFile(filePath)
	} else {
		viper.SetConfigName("config") // Config file name (without extension)
		viper.AddConfigPath(".")      // Look for the config file in the current directory
	}

	viper.SetConfigType("yaml") // Config file type (can be JSON, TOML, etc.)

	// Environment variables support (PRODUCT_DATABASE_HOST, PRODUCT_APPPORT, etc.)
	viper.SetEnvPrefix("PRODUCT")
	viper.SetEnvKeyReplacer(strings.NewReplacer(".", "_"))
	viper.AutomaticEnv()

	// Try to read config file; ignore if not found
	if err := viper.ReadInConfig(); err != nil {
		if _, ok := err.(viper.ConfigFileNotFoundError); !ok {
			// Log but don't fail on missing config file
		}
	}

	config := &Config{}

	// Manually read from viper to ensure env vars override config file
	config.Database.Host = viper.GetString("database.host")
	config.Database.Port = viper.GetInt("database.port")
	config.Database.User = viper.GetString("database.user")
	config.Database.Password = viper.GetString("database.password")
	config.Database.DBName = viper.GetString("database.dbname")
	config.Database.Debug = viper.GetBool("database.debug")
	config.AppPort = viper.GetString("appport")
	config.GrpcPort = viper.GetString("grpcport")
	config.ImagePath = viper.GetString("imagepath")
	config.ExternalConnection.AuthService.Host = viper.GetString("externalconnection.authservice.host")

	// Debug: print loaded config
	fmt.Printf("DEBUG: Loaded config - Host: %s, Port: %d, User: %s, DBName: %s\n",
		config.Database.Host, config.Database.Port, config.Database.User, config.Database.DBName)
	fmt.Printf("DEBUG: AppPort: %s, ImagePath: %s, AuthHost: %s\n",
		config.AppPort, config.ImagePath, config.ExternalConnection.AuthService.Host)

	return config, nil
}
