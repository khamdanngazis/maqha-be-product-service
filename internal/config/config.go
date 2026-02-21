// internal/config/config.go

package config

import (
	"fmt"
	"os"
	"path/filepath"
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

// Config holds the application configuration.
type Config struct {
	Database           DatabaseConfig
	ExternalConnection struct {
		AuthService struct {
			Host string
		}
	}
	AppPort   string
	GrpcPort  string
	ImagePath string
}

// LoadConfig loads configuration from a specified file path, environment variables, and/or config files.
func LoadConfig(filePath string) (*Config, error) {
	if filePath != "" {
		resolvedPath, err := resolveConfigPath(filePath)
		if err != nil {
			return nil, err
		}
		viper.SetConfigFile(resolvedPath)
	} else {
		viper.SetConfigName("config") // Config file name (without extension)
		viper.AddConfigPath(".")      // Look for the config file in the current directory
	}

	viper.SetConfigType("yaml") // Config file type (can be JSON, TOML, etc.)

	// Environment variables support (PRODUCT_DATABASE_HOST, PRODUCT_APPPORT, etc.)
	viper.SetEnvPrefix("PRODUCT")
	viper.SetEnvKeyReplacer(strings.NewReplacer(".", "_"))
	viper.AutomaticEnv()

	if err := viper.ReadInConfig(); err != nil {
		if _, ok := err.(viper.ConfigFileNotFoundError); !ok {
			return nil, fmt.Errorf("error reading config file: %v", err)
		}
	}

	config := &Config{}

	// Unmarshal the configuration into the Config struct
	if err := viper.Unmarshal(config); err != nil {
		return nil, fmt.Errorf("error unmarshalling config: %v", err)
	}

	return config, nil
}

func resolveConfigPath(filePath string) (string, error) {
	if filePath == "" {
		return "", nil
	}

	if _, err := os.Stat(filePath); err == nil {
		return filePath, nil
	} else if err != nil && !os.IsNotExist(err) {
		return "", fmt.Errorf("error reading config file: %v", err)
	}

	execPath, err := os.Executable()
	if err == nil {
		execDir := filepath.Dir(execPath)
		candidate := filepath.Join(execDir, filePath)
		if _, statErr := os.Stat(candidate); statErr == nil {
			return candidate, nil
		} else if statErr != nil && !os.IsNotExist(statErr) {
			return "", fmt.Errorf("error reading config file: %v", statErr)
		}
	}

	return "", fmt.Errorf("error reading config file: open %s: no such file or directory", filePath)
}
