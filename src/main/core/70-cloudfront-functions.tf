resource "aws_cloudfront_function" "www_react_app" {
  name    = format("www-react-app-%s", var.env)
  comment = "Redirects to www URL (if necessary) and appends index.html (if missing). It also handles the public catalog URI"

  runtime = "cloudfront-js-1.0"
  publish = true

  code = <<-EOT
    function handler(event) {
      var request = event.request;

      var host = request.headers.host.value;
      if (!(host.startsWith('www.'))) {
          var response = {
              statusCode: 301,
              statusDescription: 'Moved Permanently',
              headers: {
                'location': { value: 'https://www.' + host + request.uri }
              }
          };

          return response;
      }

      var eserviceRegex = /^\/catalogo\/.+/

      if (eserviceRegex.test(request.uri)) {
        request.uri = "/catalogo/[id]"
      }

      if (request.uri.endsWith('/')) {
          request.uri += 'index.html';
      }
      else if (!request.uri.includes('.')) {
          request.uri += '/index.html';
      }

      return request;
    }
  EOT
}
