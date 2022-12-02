resource "aws_s3_bucket" "images" {
  bucket = "dalle-preview-images"
}

resource "aws_s3_bucket_acl" "images" {
  bucket = aws_s3_bucket.images.id
  acl    = "private"
}
