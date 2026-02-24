package repository

import (
	"context"
	"crypto/tls"
	"errors"
	"maqhaa/library/logging"
	"maqhaa/library/middleware"
	"maqhaa/product_service/external/model"

	"github.com/sirupsen/logrus"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials"
	"google.golang.org/grpc/credentials/insecure"
)

type UserRepository interface {
	GetUser(ctx context.Context, token string) (*model.UserData, error)
}

type userRepository struct {
	connetionURl string
	useTLS       bool
}

func NewUserRepository(connetionURl string, useTLS bool) UserRepository {
	return &userRepository{
		connetionURl: connetionURl,
		useTLS:       useTLS,
	}
}

func (r *userRepository) GetUser(ctx context.Context, token string) (*model.UserData, error) {
	requestID, _ := ctx.Value(middleware.RequestIDKey).(string)
	req := &model.GetUserRequest{
		Token: token, // Replace with a valid product ID for your test data
	}

	// Configure gRPC connection based on useTLS setting
	var opts []grpc.DialOption
	if r.useTLS {
		// Production: use TLS credentials
		tlsConfig := &tls.Config{}
		creds := credentials.NewTLS(tlsConfig)
		opts = append(opts, grpc.WithTransportCredentials(creds))
		logging.Log.WithFields(logrus.Fields{"request_id": requestID}).Info("Using TLS for gRPC connection")
	} else {
		// Development: use insecure connection
		opts = append(opts, grpc.WithTransportCredentials(insecure.NewCredentials()))
		logging.Log.WithFields(logrus.Fields{"request_id": requestID}).Info("Using insecure gRPC connection")
	}

	conn, err := grpc.Dial(r.connetionURl, opts...)
	if err != nil {
		logging.Log.WithFields(logrus.Fields{"request_id": requestID}).Errorf("Error GetUser  %s", err.Error())
		return nil, err
	}
	defer conn.Close()

	client := model.NewUserClient(conn)

	resp, err := client.GetUser(context.Background(), req)
	if err != nil {
		logging.Log.WithFields(logrus.Fields{"request_id": requestID}).Errorf("Error GetUser  %s", err.Error())
		return nil, err
	}
	if resp.Code != 0 {
		logging.Log.WithFields(logrus.Fields{"request_id": requestID}).Errorf("Error GetUser  %v", resp)
		return nil, errors.New(resp.Message)
	}

	if resp.Data == nil {
		logging.Log.WithFields(logrus.Fields{"request_id": requestID}).Errorf("Error GetUser  %s", errors.New("Data User Nill"))
		return nil, errors.New("Data User Nill")
	}
	return resp.Data, nil
}
