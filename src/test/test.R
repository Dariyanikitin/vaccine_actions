#-------------------------------------------------------------------------------        
# SET UP
#-------------------------------------------------------------------------------
# Generate output folder 
dir.create("outputs", showWarnings = FALSE)

#parameters
orderly::orderly_parameters(input = "text")

#artefacts
orderly::orderly_artefact(
  description = 
    "saved text file",
  files = "outputs/test.txt"
)

#-------------------------------------------------------------------------------        
# TASKS
#-------------------------------------------------------------------------------
text <- c("This is line 1", paste0("This is line 2, from the parameters: ",
                                   input))

#-------------------------------------------------------------------------------        
# SAVE
#-------------------------------------------------------------------------------
readr::write_lines(text, "outputs/test.txt")
