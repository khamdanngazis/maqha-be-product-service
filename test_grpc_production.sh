#!/bin/bash

echo "=== Testing gRPC Auth Service Connection ==="
echo ""

# Check if grpcurl is installed
if ! command -v grpcurl &> /dev/null; then
    echo "grpcurl not found. Installing..."
    go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest
    export PATH=$PATH:$(go env GOPATH)/bin
fi

GRPC_ENDPOINT="maqha-be-auth-service-production.up.railway.app:443"
echo "Testing: $GRPC_ENDPOINT"
echo ""

# Test with TLS
echo "=== Test 1: GetUser with TLS (admin_token_12345) ==="
grpcurl -d '{"token": "admin_token_12345"}' \
  "$GRPC_ENDPOINT" model.User.GetUser 2>&1 || echo "Failed with TLS"
echo ""

# Test with staff token
echo "=== Test 2: GetUser with TLS (staff_token_12345) ==="
grpcurl -d '{"token": "staff_token_12345"}' \
  "$GRPC_ENDPOINT" model.User.GetUser 2>&1 || echo "Failed with TLS"
echo ""

echo "=== Tests Completed ==="
