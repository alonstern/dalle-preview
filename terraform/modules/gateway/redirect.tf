# create the method GET and assign it to the resource /docs
resource "aws_api_gateway_method" "main_page" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_rest_api.api.root_resource_id
  http_method   = "GET"
  authorization = "NONE"
}
# create the mock integration which will returns the statusCode 301 on the previous method GET of the /docs
resource "aws_api_gateway_integration" "main_page" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_rest_api.api.root_resource_id
  http_method = aws_api_gateway_method.main_page.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" : "{ \"statusCode\": 301 }"
  }
}
# create the method response and enable the header Location
resource "aws_api_gateway_method_response" "main_page" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_rest_api.api.root_resource_id
  http_method = aws_api_gateway_method.main_page.http_method
  status_code = "301"
  response_parameters = {
    "method.response.header.Location" : true
  }
}
# Fill the previous header with the destination. Notice the syntax of the location with single quotes wrapped by doubles.
resource "aws_api_gateway_integration_response" "main_page" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_rest_api.api.root_resource_id
  http_method = aws_api_gateway_method.main_page.http_method
  status_code = aws_api_gateway_method_response.main_page.status_code
  response_parameters = {
    "method.response.header.Location" : "'/welcome'"
  }
}