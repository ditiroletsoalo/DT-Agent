if (file.exists("secrets.R")) source("secrets.R")


library(shiny)
library(ellmer)
library(pdftools)
library(rsconnect)

cv_text <- paste(pdf_text("Letsoalo_Ditiro_CV.pdf"), collapse = "\n")

ui <- fluidPage(
  tags$head(tags$style(HTML("
    body { font-family: sans-serif; max-width: 700px; margin: auto; padding: 20px; }
    .chat-box { height: 400px; overflow-y: auto; border: 1px solid #ddd;
                padding: 15px; border-radius: 8px; background: #f9f9f9; }
    .user-msg { text-align: right; color: #333; margin: 8px 0; }
    .agent-msg { text-align: left; color: #0057b8; margin: 8px 0; }
  "))),
  
  titlePanel("Chat with Ditiro's Agent 👋"),
  
  div(class = "chat-box", uiOutput("chat_history")),
  br(),
  fluidRow(
    column(10, textInput("user_input", label = NULL, placeholder = "Ask me anything about Ditiro...")),
    column(2, actionButton("send", "Send", class = "btn-primary"))
  )
)

server <- function(input, output, session) {
  
  # One chat session per user
  chat <- chat_mistral(model = "mistral-small")
  chat$chat(paste0(
    "You are a friendly assistant representing Ditiro Letsoalo. ",
    "Here is his CV:\n\n", cv_text,
    "\n\nAnswer questions about Ditiro based on this. Be concise and professional."
  ))
  
  history <- reactiveVal(list())
  
  observeEvent(input$send, {
    req(input$user_input)
    user_msg <- input$user_input
    updateTextInput(session, "user_input", value = "")
    
    response <- chat$chat(user_msg)
    
    history(c(history(), list(
      list(role = "user", text = user_msg),
      list(role = "agent", text = response)
    )))
  })
  
  output$chat_history <- renderUI({
    msgs <- history()
    if (length(msgs) == 0) return(p("Ask me about Ditiro's skills, experience, projects..."))
    
    lapply(msgs, function(m) {
      if (m$role == "user")
        div(class = "user-msg", strong("You: "), m$text)
      else
        div(class = "agent-msg", strong("Agent: "), m$text)
    })
  })
}

shinyApp(ui, server)



