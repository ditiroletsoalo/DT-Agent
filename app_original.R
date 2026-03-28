if (file.exists("secrets.R")) source("secrets.R")

library(shiny)
library(ellmer)
library(pdftools)
library(commonmark)
library(later)

# ── DATA PREPARATION ──
cv_text <- if (file.exists("Letsoalo_Ditiro_CV.pdf")) {
  paste(pdf_text("Letsoalo_Ditiro_CV.pdf"), collapse = "\n")
} else {
  "Information about Ditiro Letsoalo's professional background is currently being updated."
}

if (!dir.exists("www")) dir.create("www")
if (file.exists("ditiro.jpg")) file.copy("ditiro.jpg", "www/ditiro.jpg", overwrite = TRUE)

# ── USER INTERFACE ──
ui <- fluidPage(
  tags$head(
    tags$link(rel = "preconnect", href = "https://fonts.googleapis.com"),
    tags$link(rel = "stylesheet",
              href = "https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=DM+Sans:wght@300;400;500&display=swap"),
    tags$style(HTML("
      * { box-sizing: border-box; margin: 0; padding: 0; }
      body {
        background-color: #0a0a0f;
        background-image: radial-gradient(ellipse at 20% 50%, rgba(99,60,255,0.15) 0%, transparent 50%);
        font-family: 'DM Sans', sans-serif;
        color: #e8e8f0;
        min-height: 100vh;
      }
      .container-fluid { padding: 0 !important; }
      .page-wrap { max-width: 780px; margin: 0 auto; padding: 48px 24px 80px; }

      /* Welcome Screen */
      .welcome-screen {
        display: flex; flex-direction: column; align-items: center;
        justify-content: center; min-height: 70vh; text-align: center;
        animation: fadeUp 0.8s ease;
      }
      .welcome-screen h2 {
        font-family: 'Syne', sans-serif; font-size: 3.5rem; font-weight: 800;
        background: linear-gradient(135deg, #ffffff 30%, #a78bfa);
        -webkit-background-clip: text; -webkit-text-fill-color: transparent;
        margin-bottom: 10px; letter-spacing: -2px;
      }
      .name-input-wrap { display: flex; gap: 12px; width: 100%; max-width: 420px; margin-top: 25px; }
      #visitor_name {
        background: rgba(255,255,255,0.06); border: 1px solid rgba(167,139,250,0.3);
        border-radius: 12px; color: white; padding: 15px; flex: 1; outline: none;
        font-size: 1.05rem;
      }
      #start_chat {
        background: linear-gradient(135deg, #633cff, #a78bfa) !important;
        border: none !important; border-radius: 12px !important; color: white !important;
        padding: 0 30px !important; font-weight: 600 !important; cursor: pointer !important;
      }

      /* Chat Elements */
      .big-greeting {
        font-family: 'Syne', sans-serif; font-size: 3rem; font-weight: 800;
        background: linear-gradient(90deg, #a78bfa, #f472b6);
        -webkit-background-clip: text; -webkit-text-fill-color: transparent;
        margin-bottom: 5px;
      }
      .hero-sub { color: #b8b8dc; font-size: 1rem; margin-bottom: 20px; font-weight: 300; }
      .social-links { display: flex; justify-content: center; gap: 12px; margin-bottom: 28px; }
      .social-links a, .cv-btn {
        display: inline-flex; align-items: center; gap: 6px; border-radius: 20px;
        padding: 6px 16px; text-decoration: none; font-size: 0.82rem; transition: all 0.2s;
      }
      .social-links a.github { background: rgba(255,255,255,0.07); border: 1px solid rgba(255,255,255,0.12); color: #e8e8f0; }
      .social-links a.linkedin { background: rgba(0,119,181,0.15); border: 1px solid rgba(0,119,181,0.3); color: #4fa3d1; }
      .cv-btn { background: rgba(167,139,250,0.12) !important; border: 1px solid rgba(167,139,250,0.3) !important; color: #a78bfa !important; }

      .chat-wrap {
        background: rgba(255,255,255,0.03); border: 1px solid rgba(255,255,255,0.08);
        border-radius: 24px; overflow: hidden; backdrop-filter: blur(20px);
      }
      .chat-top-bar { display: flex; justify-content: flex-end; padding: 12px 20px 0; }
      #clear_chat {
        background: transparent !important; border: 1px solid rgba(255,255,255,0.12) !important;
        border-radius: 10px !important; color: #7878a0 !important; padding: 6px 14px !important;
        font-size: 0.8rem !important; cursor: pointer !important;
      }

      .chat-messages {
        height: 460px; overflow-y: auto; padding: 20px 30px 30px;
        display: flex; flex-direction: column; gap: 20px; scroll-behavior: smooth;
      }
      .empty-state {
        display: flex; flex-direction: column; align-items: center;
        justify-content: center; height: 100%; gap: 14px; color: #4a4a6a; text-align: center;
      }
      .empty-state .big-text { font-family: 'Syne', sans-serif; font-size: 1.5rem; font-weight: 600; color: #c0b0f0; }

      .msg-row { display: flex; gap: 12px; align-items: flex-end; animation: fadeIn 0.3s ease both; }
      .msg-row.user { flex-direction: row-reverse; }
      .msg-avatar { width: 32px; height: 32px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 14px; flex-shrink: 0; }
      .msg-avatar.agent { background: linear-gradient(135deg, #633cff, #a78bfa); }
      .msg-avatar.user  { background: rgba(255,255,255,0.1); }

      .msg-bubble { max-width: 80%; padding: 14px 18px; border-radius: 20px; line-height: 1.7; font-size: 0.95rem; }
      .msg-bubble.agent { background: rgba(99,60,255,0.12); border: 1px solid rgba(167,139,250,0.2); color: #e8e8ff; border-bottom-left-radius: 4px; }
      .msg-bubble.user { background: rgba(255,255,255,0.08); border: 1px solid rgba(255,255,255,0.1); text-align: right; border-bottom-right-radius: 4px; color: #ffffff; }

      .typing-bubble { background: rgba(99,60,255,0.12); border: 1px solid rgba(167,139,250,0.2); border-radius: 20px; border-bottom-left-radius: 4px; padding: 14px 18px; display: flex; gap: 5px; }
      .typing-dot { width: 7px; height: 7px; background: #a78bfa; border-radius: 50%; animation: typingBounce 1.2s infinite; }
      .typing-dot:nth-child(2) { animation-delay: 0.2s; }
      .typing-dot:nth-child(3) { animation-delay: 0.4s; }

      .input-area { padding: 16px 20px; border-top: 1px solid rgba(255,255,255,0.07); display: flex; gap: 12px; background: rgba(0,0,0,0.3); align-items: flex-end; }
      #user_input {
        width: 100% !important; background: rgba(255,255,255,0.06) !important;
        border: 1px solid rgba(255,255,255,0.1) !important; border-radius: 14px !important;
        color: white !important; padding: 14px 16px !important; outline: none !important;
        resize: none !important; max-height: 140px !important;
      }
      #send {
        background: linear-gradient(135deg, #633cff, #4f2fcc) !important; border: none !important;
        border-radius: 14px !important; color: white !important; padding: 14px 24px !important;
        font-weight: 600 !important; cursor: pointer !important;
      }

      .footer { text-align: center; margin-top: 24px; color: #3a3a5a; font-size: 0.78rem; }
      @keyframes fadeUp  { from { opacity:0; transform:translateY(20px); } to { opacity:1; transform:translateY(0); } }
      @keyframes fadeIn  { from { opacity:0; transform:translateY(8px);  } to { opacity:1; transform:translateY(0); } }
      @keyframes typingBounce { 0%,60%,100% { transform:translateY(0); } 30% { transform:translateY(-6px); } }
    "))
  ),
  div(class = "page-wrap", uiOutput("current_view"), div(class = "footer", uiOutput("footer_text"))),
  tags$script(HTML("
    $(document).on('keypress', '#visitor_name', function(e) { if (e.which === 13) { e.preventDefault(); $('#start_chat').click(); } });
    $(document).on('keydown', '#user_input', function(e) {
      if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault(); var val = $(this).val().trim(); if (!val) return;
        Shiny.setInputValue('user_input', val, {priority: 'event'}); $(this).val('').css('height', 'auto');
        setTimeout(function() { $('#send').click(); }, 50);
      }
    });
    $(document).on('input', '#user_input', function() { this.style.height = 'auto'; this.style.height = Math.min(this.scrollHeight, 140) + 'px'; });
    
    // Auto-scroll handler
    Shiny.addCustomMessageHandler('scrollBottom', function(msg) {
      setTimeout(function() {
        var el = document.getElementById('chat_messages');
        if(el) { el.scrollTop = el.scrollHeight; }
      }, 150); 
    });
    
    Shiny.addCustomMessageHandler('focusInput', function(msg) { setTimeout(function(){ var inp = document.getElementById('user_input'); if(inp) inp.focus(); }, 120); });
  "))
)

# ── SERVER LOGIC ──
server <- function(input, output, session) {
  birth_date <- as.Date("2001-03-30")
  today <- Sys.Date()
  ditiro_age <- as.numeric(difftime(today, birth_date, units = "weeks")) %/% 52.1775
  
  chat <- chat_mistral(model = "mistral-small", api_args = list(temperature = 0))
  
  chat$chat(paste0(
    "You are Ditiro Letsoalo's personal AI assistant. Speak confidently and warmly.\n\n",
    
    "── CONVERSATIONAL ETIQUETTE ──\n",
    "1. If asked 'How are you?' or similar, respond warmly (e.g., 'I'm doing wonderful, thank you for asking!') and ALWAYS ask the user how they are doing.\n",
    "2. If asked about the user or their name, respond by explicitly mentioning the user's name. Mention details they have told you about themselves during this conversation, but do NOT confuse this with Ditiro's professional background.\n",
    "3. NEVER say 'I don't have feelings' or 'I am a virtual assistant'. Keep the persona seamless and polite.\n",
    "4. Keep your answers focused on Ditiro's professional journey.\n\n",
    
    "── STRICT TRUTH RULE ──\n",
    "1. You ONLY know facts provided in the background below.\n",
    "2. If a user asks about something NOT in the text, refuse politely.\n",
    "3. Refusal Phrase: 'I don't have information on that, but I can tell you about his professional journey in Data Science!'\n\n",
    
    "── RICH SKILLS DELIVERY (MANDATORY) ──\n",
    "When asked about skills, provide deep, engaging descriptions—not just bullet points. Use multiple emojis per section to make it visually pop.\n",
    "Example structure:\n",
    "\U0001f4ca **Bayesian Inference**: Deep focus on quantifying uncertainty... using **R** and **Stan**.\n",
    "\U0001f4bb **BI Engineering**: Building interactive dashboards at **YoYo Rewards** with **SQL** and **Amazon QuickSight**.\n\n",
    
    "── BACKGROUND DATA ──\n",
    "NAME: Ditiro Letsoalo\n",
    "AGE: ", ditiro_age, " years old.\n",
    "CURRENT ROLE: BI Engineer Graduate at **YoYo Rewards** (started Feb 2026).\n",
    "ACADEMICS: 2nd Year MSc Statistics at **UCT**. B.BusSci Analytics (UCT).\n",
    "RESEARCH: 'Prediction of Extreme Events using Bayesian Forecasting' (Focus: Extreme floods).\n",
    "CORE SKILLS: **Bayesian Statistics**, **Business Intelligence**, **SQL**, **Amazon QuickSight**, **Python**, **R**, **LaTeX**.\n\n",
    "CV CONTENT:\n", cv_text,
    "\n\nPHOTO TRIGGER:\n",
    "If asked for a photo, respond ONLY with: SHOW_PHOTO Here’s Ditiro’s photo! \U0001f4f8"
  ))
  
  history <- reactiveVal(list()); waiting <- reactiveVal(FALSE); visitor_name <- reactiveVal(NULL)
  
  observeEvent(input$start_chat, {
    name <- trimws(input$visitor_name)
    if (nchar(name) > 0) {
      formatted_name <- paste0(toupper(substr(name, 1, 1)), substr(name, 2, nchar(name)))
      visitor_name(formatted_name)
      
      # Immediate Greeting Logic
      waiting(TRUE)
      response <- chat$chat(paste0("Visitor's name is ", formatted_name, ". Greet them warmly and ask how they are doing today."))
      waiting(FALSE)
      
      # Add greeting to history immediately
      history(c(history(), list(list(role = "agent", text = response, photo = FALSE))))
      session$sendCustomMessage("scrollBottom", list())
    }
  })
  
  output$download_cv <- downloadHandler(
    filename = function() { "Letsoalo_Ditiro_CV.pdf" },
    content = function(file) { if (file.exists("Letsoalo_Ditiro_CV.pdf")) file.copy("Letsoalo_Ditiro_CV.pdf", file) }
  )
  
  observeEvent(input$clear_chat, { history(list()); waiting(FALSE); session$sendCustomMessage("focusInput", list()) })
  
  observeEvent(input$send, {
    req(input$user_input, nchar(trimws(input$user_input)) > 0)
    user_msg <- trimws(input$user_input); updateTextInput(session, "user_input", value = "")
    history(c(history(), list(list(role = "user", text = user_msg)))); waiting(TRUE)
    
    session$sendCustomMessage("scrollBottom", list())
    
    response <- tryCatch(chat$chat(user_msg), error = function(e) "Sorry, something went wrong. Try again!")
    waiting(FALSE)
    
    if (grepl("SHOW_PHOTO", response)) {
      clean <- trimws(gsub("SHOW_PHOTO", "", response))
      history(c(history(), list(list(role = "agent", text = clean, photo = TRUE))))
    } else {
      history(c(history(), list(list(role = "agent", text = response, photo = FALSE))))
    }
    
    later::later(function() { session$sendCustomMessage("scrollBottom", list()) }, 0.2)
    session$sendCustomMessage("focusInput", list())
  })
  
  output$current_view <- renderUI({
    if (is.null(visitor_name())) {
      return(div(class = "welcome-screen", div(style = "font-size:3rem; margin-bottom:16px;", "\U0001f44b"),
                 tags$h2("Connect with Ditiro"), tags$p("BI Engineer @ Yoyo | MSc Candidate (UCT)"),
                 div(class = "name-input-wrap", tags$input(id = "visitor_name", type = "text", placeholder = "What's your name?"), actionButton("start_chat", "Let's Talk \u2192"))))
    }
    h <- as.integer(format(Sys.time(), "%H")); greet <- if (h>3 & h < 12) "Good Morning" else if (h>11 & h < 17) "Good Afternoon" else if (h>16 & h<12) "Good Evening" else "Hey"
    
    bubbles <- if(length(history()) == 0) {
      div(class = "empty-state", div(style = "font-size:2rem; opacity:0.4;", "\U0001f4ac"), div(class = "big-text", "Ask me anything about Ditiro!"))
    } else {
      lapply(history(), function(m) {
        if (m$role == "user") {
          div(class = "msg-row user", div(class = "msg-avatar user", "\U0001f464"), div(class = "msg-bubble user", m$text))
        } else {
          photo <- if (isTRUE(m$photo)) tags$img(src = "ditiro.jpg", style = "width:180px; height:180px; object-fit:cover; border-radius:12px; display:block; margin-bottom:12px;") else NULL
          div(class = "msg-row agent", div(class = "msg-avatar agent", "\u2736"), div(class = "msg-bubble agent", photo, HTML(commonmark::markdown_html(m$text))))
        }
      })
    }
    
    if (waiting()) bubbles <- c(bubbles, list(div(class = "msg-row agent", div(class = "msg-avatar agent", "\u2736"), div(class = "typing-bubble", div(class = "typing-dot"), div(class = "typing-dot"), div(class = "typing-dot")))))
    
    div(div(class = "hero", style = "text-align:center; margin-bottom:10px;", div(class = "big-greeting", paste0(greet, ", ", visitor_name(), "!")),
            div(class = "hero-sub", "Ask me anything about Ditiro's journey."),
            div(class = "social-links", tags$a(href = "https://github.com/ditiroletsoalo", target = "_blank", class = "github", "\u2395 GitHub"),
                tags$a(href = "https://www.linkedin.com/in/ditiro-letsoalo-3b908722a/", target = "_blank", class = "linkedin", "in LinkedIn"), downloadButton("download_cv", "\u21e9 CV", class = "cv-btn"))),
        div(class = "chat-wrap", div(class = "chat-top-bar", actionButton("clear_chat", "\u21ba Clear Chat")),
            div(class = "chat-messages", id = "chat_messages", bubbles),
            div(class = "input-area", tags$textarea(id = "user_input", class = "form-control", rows = "1", placeholder = "Ask me anything about Ditiro!"), actionButton("send", "Send \u2191"))))
  })
  output$footer_text <- renderUI({ if (!is.null(visitor_name())) tags$span("Powered by Mistral AI \u00b7 Built with R Shiny") })
}

shinyApp(ui, server)