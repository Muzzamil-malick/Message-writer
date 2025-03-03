library(shiny)
library(dplyr)
library(stringr) # For str_match_all

# Define the UI
ui <- fluidPage(
  titlePanel("TEXT Formatter"),
  
  sidebarLayout(
    sidebarPanel(
      helpText("Paste your tab-delimited data below and click 'Convert'. Ensure the data matches the structure."),
      
      # Text area to paste data
      textAreaInput("data_input", "Paste Data Here:", "", rows = 10, placeholder = "Paste tab-delimited data here..."),
      
      # Action button to trigger conversion
      actionButton("convert_btn", "Convert"),
      
      # Download button
      downloadButton("download_btn", "Download Output")
    ),
    
    mainPanel(
      h3("Formatted Output"),
      verbatimTextOutput("formatted_output"),
      
      h3("Debugging:"),
      tableOutput("debug_table")
    )
  )
)

# Define the server logic
server <- function(input, output, session) {
  
  # Reactive function to process the data when the button is clicked
  formatted_data <- eventReactive(input$convert_btn, {
    # Get the input data
    raw_data <- input$data_input
    
    # Check if data is provided
    if (nchar(raw_data) == 0) {
      return("No data provided. Please paste data into the text area.")
    }
    
    # Convert the pasted data into a dataframe
    df <- tryCatch(
      read.table(text = raw_data, sep = "\t", header = TRUE, stringsAsFactors = FALSE, check.names = FALSE),
      error = function(e) return(NULL)
    )
    
    # If conversion failed, show an error
    if (is.null(df)) {
      return("Error: Unable to parse the input data. Ensure it is tab-delimited and has proper column headers.")
    }
    
    # Clean column names by removing extra spaces and line breaks
    colnames(df) <- gsub("\\s+", " ", colnames(df)) # Replace multiple spaces/newlines with single space
    
    # Check for required columns
    required_cols <- c("SOURCE", "LABNO", "DISTRICT", "SITE NAME", "DATE COLLECTION", "Closest genetic match", "Genetic cluster")
    
    if (!all(required_cols %in% colnames(df))) {
      missing_cols <- setdiff(required_cols, colnames(df))
      return(paste("Error: Missing required columns:", paste(missing_cols, collapse = ", ")))
    }
    
    # Function to determine the prefix based on SOURCE
    get_prefix <- function(source) {
      if (grepl("GRAB", source, ignore.case = TRUE)) {
        return("G-")
      } else if (grepl("BMFS", source, ignore.case = TRUE)) {
        return("BMFS-")
      } else {
        return("")
      }
    }
    
    # Function to format a single row with bold formatting for the genetic cluster content
    format_row <- function(row) {
      prefix <- get_prefix(row[["SOURCE"]]) # Get the prefix from SOURCE
      lab_code <- paste0(trimws(prefix), trimws(row[["LABNO"]])) # Add the prefix to LABNO
      id_code <- trimws(row[["IDCODE"]])
      location <- paste0("*", trimws(row[["DISTRICT"]]), ", site= ", trimws(row[["SITE NAME"]]), "*")  # Bold the location
      collection_date <- paste("Collection Date:", trimws(row[["DATE COLLECTION"]]))
      
      # Bold only the content of the genetic cluster
      genetic_cluster <- paste("Genetic Cluster: *", trimws(row[["Genetic cluster"]]), "*", sep = "")  # Bold the content of the genetic cluster
      
      closest_match <- row[["Closest genetic match"]]  # Display closest genetic match as is
      
      # Combine the formatted fields
      paste(lab_code, id_code, location, collection_date, 
            genetic_cluster,  paste("Closest Genetic Match:", closest_match),  sep = "\n")
    }
    
    # Apply the formatting function to each row and insert a blank line between rows
    formatted_output <- apply(df, 1, format_row)
    formatted_output <- paste(formatted_output, collapse = "\n\n") # Add blank lines between rows
    
    # Return the formatted data as a character vector
    formatted_output
  })
  
  # Output the formatted data
  output$formatted_output <- renderText({
    formatted_data()
  })
  
  # Output the debug table to inspect the parsed dataframe
  output$debug_table <- renderTable({
    raw_data <- input$data_input
    if (nchar(raw_data) == 0) {
      return(NULL)
    }
    df <- tryCatch(
      read.table(text = raw_data, sep = "\t", header = TRUE, stringsAsFactors = FALSE, check.names = FALSE),
      error = function(e) return(NULL)
    )
    if (is.null(df)) {
      return(NULL)
    }
    colnames(df) <- gsub("\\s+", " ", colnames(df)) # Replace multiple spaces/newlines with single space
    df
  })
  
  # Allow the formatted data to be downloaded
  output$download_btn <- downloadHandler(
    filename = function() {
      paste("formatted_output_", Sys.Date(), ".txt", sep = "")
    },
    content = function(file) {
      writeLines(formatted_data(), file)
    }
  )
}

# Run the application
shinyApp(ui = ui, server = server)
