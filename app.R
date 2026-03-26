if (file.exists("secrets.R")) source("secrets.R")

library(shiny)
library(ellmer)
library(pdftools)
library(commonmark)

# ── DATA PREP ──
cv_text <- tryCatch({
  paste(pdf_text("Letsoalo_Ditiro_CV.pdf"), collapse = "\n")
}, error = function(e) "BI Engineer & MSc Statistics candidate.")

ui <- fluidPage(
  tags$head(
    tags$link(rel = "preconnect", href = "https://fonts.googleapis.com"),
    tags$link(rel = "stylesheet", href = "https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=DM+Sans:wght@300;400;500&display=swap"),
    tags$style(HTML("
      * { box-sizing: border-box; margin: 0; padding: 0; }
      body {
        background-color: #0a0a0f;
        background-image: radial-gradient(ellipse at 20% 50%, rgba(99, 60, 255, 0.15) 0%, transparent 50%);
        font-family: 'DM Sans', sans-serif;
        color: #e8e8f0;
        min-height: 100vh;
      }
      .page-wrap { max-width: 780px; margin: 0 auto; padding: 48px 24px 80px; }

      /* ── WELCOME SCREEN ── */
      .welcome-screen {
        display: flex; flex-direction: column; align-items: center; justify-content: center;
        min-height: 70vh; text-align: center; animation: fadeUp 0.8s ease;
      }
      .welcome-screen h2 {
        font-family: 'Syne', sans-serif; font-size: 3.5rem; font-weight: 800;
        background: linear-gradient(135deg, #ffffff 30%, #a78bfa);
        -webkit-background-clip: text; -webkit-text-fill-color: transparent;
        margin-bottom: 10px; letter-spacing: -2px;
      }
      .name-input-wrap { display: flex; gap: 12px; width: 100%; max-width: 420px; margin-top: 25px; }
      #visitor_name { 
        background: rgba(255,255,255,0.06); border: 1px solid rgba(167, 139, 250, 0.3);
        border-radius: 12px; color: white; padding: 15px; flex: 1; outline: none; font-size: 1rem;
      }
      #start_chat { 
        background: linear-gradient(135deg, #633cff, #a78bfa); border: none; 
        border-radius: 12px; color: white; padding: 0 30px; font-weight: 600; cursor: pointer;
      }

      /* ── CHAT SCREEN ── */
      .big-greeting {
        font-family: 'Syne', sans-serif; font-size: 3rem; font-weight: 800;
        background: linear-gradient(90deg, #a78bfa, #f472b6);
        -webkit-background-clip: text; -webkit-text-fill-color: transparent;
        margin-bottom: 5px; text-shadow: 0 0 30px rgba(167, 139, 250, 0.25);
        animation: fadeUp 0.5s ease;
      }
      .hero-sub { color: #b8b8dc; font-size: 1.1rem; margin-bottom: 35px; font-weight: 300; }

      .chat-wrap {
        background: rgba(255,255,255,0.03); border: 1px solid rgba(255,255,255,0.08);
        border-radius: 24px; overflow: hidden; backdrop-filter: blur(20px);
      }
      .chat-messages { height: 480px; overflow-y: auto; padding: 30px; display: flex; flex-direction: column; gap: 20px; scroll-behavior: smooth; }
      
      .msg-row { display: flex; gap: 12px; }
      .msg-row.user { flex-direction: row-reverse; }
      
      .msg-bubble { max-width: 82%; padding: 16px 20px; border-radius: 20px; line-height: 1.7; font-size: 0.98rem; }
      
      .msg-bubble.agent { 
        background: rgba(99, 60, 255, 0.12); border: 1px solid rgba(167, 139, 250, 0.2); 
        color: #e8e8ff; border-bottom-left-radius: 4px;
      }
      .msg-bubble.agent strong { color: #ffffff; font-weight: 700; }
      .msg-bubble.agent ul { margin-left: 20px; margin-top: 10px; color: #d1d1f0; }
      .msg-bubble.agent li { margin-bottom: 8px; }
      
      .msg-bubble.user { 
        background: rgba(255,255,255,0.08); border: 1px solid rgba(255,255,255,0.1); 
        text-align: right; border-bottom-right-radius: 4px; color: #ffffff;
      }

      .input-area { padding: 25px; border-top: 1px solid rgba(255,255,255,0.07); display: flex; gap: 12px; background: rgba(0,0,0,0.3); }
      #user_input { 
        flex: 1; background: rgba(255,255,255,0.06); border: 1px solid rgba(255,255,255,0.1); 
        border-radius: 14px; color: white; padding: 14px; outline: none; font-size: 1rem;
      }
      #send { 
        background: linear-gradient(135deg, #633cff, #4f2fcc); border: none; 
        border-radius: 14px; color: white; padding: 0 25px; font-weight: 600; cursor: pointer;
      }

      @keyframes fadeUp { from { opacity: 0; transform: translateY(20px); } to { opacity: 1; transform: translateY(0); } }
    "))
  ),
  
  div(class = "page-wrap",
      uiOutput("current_view")
  ),
  
  tags$script(HTML("
    $(document).on('keypress', '#visitor_name', function(e) { if (e.which == 13) { $('#start_chat').click(); } });
    $(document).on('keypress', '#user_input', function(e) { if (e.which == 13) { $('#send').click(); } });

    // MutationObserver monitors the chat box and scrolls down as text is added
    const observer = new MutationObserver(() => {
      const el = document.getElementById('chat_messages');
      if (el) { el.scrollTop = el.scrollHeight; }
    });

    $(document).on('shiny:visualchange', function() {
      const target = document.getElementById('chat_messages');
      if (target) { observer.observe(target, { childList: true, subtree: true }); }
    });
  "))
)

server <- function(input, output, session) {
  
  # Initialize Chat
  chat <- chat_mistral(model = "mistral-small", api_key = Sys.getenv("MISTRAL_API_KEY"))
  chat$chat(paste0(
    "You are the AI for Ditiro Letsoalo. Context: ", cv_text,
    "\nRULES: Be professional and warm. Use bold text and bullet points."
  ))
  
  history <- reactiveVal(list())
  visitor_name <- reactiveVal(NULL)
  
  observeEvent(input$start_chat, {
    req(input$visitor_name)
    visitor_name(trimws(input$visitor_name))
  })
  
  observeEvent(input$send, {
    req(input$user_input)
    user_msg <- input$user_input
    updateTextInput(session, "user_input", value = "")
    
    # Add User Message
    history(c(history(), list(list(role = "user", text = user_msg))))
    
    # Create empty Agent bubble
    history(c(history(), list(list(role = "agent", text = ""))))
    
    # Stream text manually to avoid extract_text 'non-function' error
    full_response <- ""
    tryCatch({
      s <- chat$stream(user_msg)
      for (chunk in s) {
        if (!is.null(chunk$choices[[1]]$delta$content)) {
          new_text <- chunk$choices[[1]]$delta$content
          full_response <- paste0(full_response, new_text)
          
          # Update UI history live
          curr_hist <- history()
          curr_hist[[length(curr_hist)]]$text <- full_response
          history(curr_hist)
        }
      }
    }, error = function(e) {
      curr_hist <- history()
      curr_hist[[length(curr_hist)]]$text <- "I'm offline right now."
      history(curr_hist)
    })
  })
  
  output$current_view <- renderUI({
    if (is.null(visitor_name())) {
      div(class = "welcome-screen",
          tags$h2("Connect with Ditiro"),
          tags$p("Data Science • BI Engineering • Bayesian Research"),
          div(class = "name-input-wrap",
              tags$input(id = "visitor_name", type = "text", placeholder = "What's your name?"),
              actionButton("start_chat", "Let's Talk →")
          )
      )
    } else {
      h <- as.integer(format(Sys.time(), "%H"))
      greet <- if (h < 12) "Good Morning" else if (h < 17) "Good Afternoon" else "Good Evening"
      
      div(
        div(class = "hero",
            div(class = "big-greeting", paste0(greet, ", ", visitor_name(), "!")),
            div(class = "hero-sub", "I'm here to answer questions about Ditiro's professional journey.")
        ),
        div(class = "chat-wrap",
            div(class = "chat-messages", id = "chat_messages",
                lapply(history(), function(m) {
                  if (m$role == "user") {
                    div(class = "msg-row user", div(class = "msg-bubble user", m$text))
                  } else {
                    formatted_html <- HTML(commonmark::markdown_html(m$text))
                    div(class = "msg-row agent", div(class = "msg-bubble agent", formatted_html))
                  }
                })
            ),
            div(class = "input-area",
                tags$input(id = "user_input", type = "text", placeholder = "Type your message here..."),
                actionButton("send", "Send ↑")
            )
        )
      )
    }
  })
}

shinyApp(ui, server)