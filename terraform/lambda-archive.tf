locals {
  # Path to the compiled JavaScript (compiled from the TypeScript files in the dist/lambdas folder after run `npm run build` first)
  build_folder = "${path.root}/../dist/lambdas"
}

data "archive_file" "create_item_zip" {
  type        = "zip"
  source_file = "${local.build_folder}/createItem.js"
  output_path = "${path.module}/zips/createItem.zip"
}

data "archive_file" "get_item_zip" {
  type        = "zip"
  source_file = "${local.build_folder}/getItem.js"
  output_path = "${path.module}/zips/getItem.zip"
}

data "archive_file" "update_item_zip" {
  type        = "zip"
  source_file = "${local.build_folder}/updateItem.js"
  output_path = "${path.module}/zips/updateItem.zip"
}

data "archive_file" "delete_item_zip" {
  type        = "zip"
  source_file = "${local.build_folder}/deleteItem.js"
  output_path = "${path.module}/zips/deleteItem.zip"
}

# Provide outputs or locals for main.tf to use the outputs of this module, or to reference them
locals {
  create_item_zip_output_path = data.archive_file.create_item_zip.output_path
  get_item_zip_output_path    = data.archive_file.get_item_zip.output_path
  update_item_zip_output_path = data.archive_file.update_item_zip.output_path
  delete_item_zip_output_path = data.archive_file.delete_item_zip.output_path
}
