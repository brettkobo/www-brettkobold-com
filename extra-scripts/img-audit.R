library(rvest)
library(tidyverse)

url_list <- list.files(path = "content/post/", pattern = ".html", full.names = TRUE)

parsed_html <- lapply(url_list, read_html)

parsed_html %>% lapply(html_nodes, css = "img")


