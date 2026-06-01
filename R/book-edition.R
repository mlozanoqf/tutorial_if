book_source_files <- function(config_path = "_quarto.yml") {
  config <- readLines(config_path, warn = FALSE, encoding = "UTF-8")
  matches <- gregexpr("[[:alnum:]_.-]+\\.qmd", config, perl = TRUE)
  files <- unique(unlist(regmatches(config, matches), use.names = FALSE))
  files <- files[file.exists(files)]

  if (!length(files)) {
    stop("No book source files were found in ", config_path, call. = FALSE)
  }

  files
}

book_source_text <- function(files) {
  parts <- lapply(files, function(file) {
    lines <- readLines(file, warn = FALSE, encoding = "UTF-8")
    paste(c(paste0("FILE: ", file), lines), collapse = "\n")
  })

  paste(unlist(parts, use.names = FALSE), collapse = "\n\n")
}

git_safe_args <- function(args) {
  repo <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
  c("-c", paste0("safe.directory=", repo), args)
}

book_text_sha <- function(text) {
  tmp <- tempfile(fileext = ".txt")
  con <- file(tmp, open = "wb")
  on.exit(unlink(tmp), add = TRUE)

  tryCatch(
    writeBin(charToRaw(enc2utf8(text)), con),
    finally = close(con)
  )

  sha <- suppressWarnings(tryCatch(
    system2(
      "git",
      git_safe_args(c("hash-object", "--no-filters", tmp)),
      stdout = TRUE,
      stderr = TRUE
    ),
    error = function(error) character()
  ))
  sha <- sha[grepl("^[0-9a-f]{40,64}$", sha)]

  if (length(sha)) {
    return(sha[[1]])
  }

  paste0("md5", unname(tools::md5sum(tmp)))
}

book_edition <- function(config_path = "_quarto.yml", n = 7) {
  files <- book_source_files(config_path)
  sha <- book_text_sha(book_source_text(files))
  short <- substr(sha, 1, n)

  list(
    sha = sha,
    short = short,
    label = paste0("Book edition: ", short)
  )
}

book_js_string <- function(x) {
  x <- gsub("\\\\", "\\\\\\\\", x)
  x <- gsub('"', '\\"', x, fixed = TRUE)
  x <- gsub("\r", "\\r", x, fixed = TRUE)
  x <- gsub("\n", "\\n", x, fixed = TRUE)
  paste0('"', x, '"')
}

book_timezone <- function() {
  timezone <- Sys.getenv("BOOK_TIMEZONE", unset = "America/Mexico_City")

  if (!nzchar(timezone)) {
    timezone <- "America/Mexico_City"
  }

  timezone
}

book_time_label <- function(time, tz = book_timezone()) {
  time <- as.POSIXlt(time, tz = tz)
  month_names <- c(
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  )
  hour24 <- as.integer(format(time, "%H"))
  hour <- hour24 %% 12

  if (hour == 0) {
    hour <- 12
  }

  paste0(
    month_names[time$mon + 1],
    " ",
    as.integer(format(time, "%d")),
    ", ",
    format(time, "%Y"),
    ", ",
    hour,
    format(time, ":%M:%S "),
    if (hour24 < 12) "am" else "pm",
    "."
  )
}

parse_git_time <- function(value) {
  value <- sub("([+-][0-9]{2}):([0-9]{2})$", "\\1\\2", value)
  as.POSIXct(value, format = "%Y-%m-%dT%H:%M:%S%z")
}

book_first_publication_time <- function(file = "index.qmd") {
  dates <- suppressWarnings(tryCatch(
    system2(
      "git",
      git_safe_args(c("log", "--follow", "--format=%aI", "--reverse", "--", file)),
      stdout = TRUE,
      stderr = TRUE
    ),
    error = function(error) character()
  ))
  dates <- dates[grepl("^\\d{4}-\\d{2}-\\d{2}T", dates)]

  if (!length(dates)) {
    return(Sys.time())
  }

  first_time <- parse_git_time(dates[[1]])

  if (is.na(first_time)) {
    return(Sys.time())
  }

  first_time
}

book_publication_number <- function(ref = "HEAD") {
  count <- suppressWarnings(tryCatch(
    system2(
      "git",
      git_safe_args(c("rev-list", "--count", ref)),
      stdout = TRUE,
      stderr = TRUE
    ),
    error = function(error) character()
  ))
  count <- count[grepl("^[0-9]+$", count)]

  if (!length(count)) {
    return(NA_integer_)
  }

  as.integer(count[[1]])
}

write_book_edition_script <- function(config_path = "_quarto.yml", n = 7) {
  edition <- book_edition(config_path, n)

  cat(
    '<script>\n',
    '(function () {\n',
    '  var editionPrefix = "Book edition: ";\n',
    '  var editionShort = ', book_js_string(edition$short), ';\n',
    '  var editionHash = ', book_js_string(edition$sha), ';\n',
    '  function applyBookEdition() {\n',
    '    var subtitle = document.querySelector("#title-block-header .subtitle");\n',
    '    if (subtitle) {\n',
    '      subtitle.textContent = "";\n',
    '      subtitle.appendChild(document.createTextNode(editionPrefix));\n',
    '      var editionCode = document.createElement("code");\n',
    '      editionCode.className = "book-edition-code";\n',
    '      editionCode.textContent = editionShort;\n',
    '      subtitle.appendChild(editionCode);\n',
    '      subtitle.title = editionPrefix + editionShort;\n',
    '      subtitle.classList.add("book-edition-subtitle");\n',
    '    }\n',
    '    document.documentElement.setAttribute("data-book-edition", editionHash);\n',
    '  }\n',
    '  if (document.readyState === "loading") {\n',
    '    document.addEventListener("DOMContentLoaded", applyBookEdition);\n',
    '  } else {\n',
    '    applyBookEdition();\n',
    '  }\n',
    '})();\n',
    '</script>\n',
    sep = ""
  )

  invisible(edition)
}

write_book_dates <- function(first_publication_file = "index.qmd") {
  published_label <- book_time_label(Sys.time())
  first_publication_label <- book_time_label(
    book_first_publication_time(first_publication_file)
  )
  publication_number <- book_publication_number()
  publication_label <- if (is.na(publication_number)) {
    "Publication: pending"
  } else {
    paste0("Publication: ", publication_number)
  }

  cat(
    '<script>\n',
    '(function () {\n',
    '  var publishedLabel = ', book_js_string(published_label), ';\n',
    '  function applyPublishedDate() {\n',
    '    var headings = document.querySelectorAll("#title-block-header .quarto-title-meta-heading");\n',
    '    headings.forEach(function (heading) {\n',
    '      if (heading.textContent.trim() !== "Published") {\n',
    '        return;\n',
    '      }\n',
    '      var item = heading.parentElement;\n',
    '      var date = item ? item.querySelector(".quarto-title-meta-contents p") : null;\n',
    '      if (date) {\n',
    '        date.textContent = publishedLabel;\n',
    '      }\n',
    '    });\n',
    '  }\n',
    '  if (document.readyState === "loading") {\n',
    '    document.addEventListener("DOMContentLoaded", applyPublishedDate);\n',
    '  } else {\n',
    '    applyPublishedDate();\n',
    '  }\n',
    '})();\n',
    '</script>\n',
    '<div class="home-publication-meta">',
    '<span class="home-publication-meta-item">',
    '<span class="home-publication-meta-label">', publication_label, '</span>',
    '</span>',
    '<span class="home-publication-meta-separator" aria-hidden="true">&middot;</span>',
    '<span class="home-publication-meta-item">',
    '<span class="home-publication-meta-label">First publication:</span>',
    '<span class="date-first-publication">', first_publication_label, '</span>',
    '</span>',
    '</div>\n',
    sep = ""
  )

  invisible(list(
    published = published_label,
    first_publication = first_publication_label,
    publication = publication_label
  ))
}
