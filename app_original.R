if (file.exists("secrets.R")) source("secrets.R")

library(shiny)
library(ellmer)
library(pdftools)
library(commonmark)

# ── DATA PREP ──
cv_text <- paste(pdf_text("Letsoalo_Ditiro_CV.pdf"), collapse = "\n")

if (!dir.exists("www")) dir.create("www")
if (file.exists("ditiro.jpg")) file.copy("ditiro.jpg", "www/ditiro.jpg", overwrite = TRUE)

# ── UI ──
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

      /* ── WELCOME SCREEN ── */
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
      .welcome-screen p { color: #7878a0; font-size: 1rem; }
      .name-input-wrap { display: flex; gap: 12px; width: 100%; max-width: 420px; margin-top: 25px; }
      #visitor_name {
        background: rgba(255,255,255,0.06); border: 1px solid rgba(167,139,250,0.3);
        border-radius: 12px; color: white; padding: 15px; flex: 1; outline: none;
        font-size: 1.05rem; font-family: 'DM Sans', sans-serif;
      }
      #visitor_name::placeholder { color: #a0a0c0; font-size: 1.05rem; }
      #visitor_name:focus { border-color: rgba(99,60,255,0.6); box-shadow: 0 0 0 3px rgba(99,60,255,0.1); }
      #start_chat {
        background: linear-gradient(135deg, #633cff, #a78bfa) !important;
        border: none !important; border-radius: 12px !important; color: white !important;
        padding: 0 30px !important; font-weight: 600 !important; cursor: pointer !important;
        font-family: 'DM Sans', sans-serif !important; font-size: 0.95rem !important;
        transition: all 0.2s !important;
      }
      #start_chat:hover { transform: translateY(-1px) !important; box-shadow: 0 4px 20px rgba(99,60,255,0.4) !important; }

      /* ── CHAT SCREEN ── */
      .big-greeting {
        font-family: 'Syne', sans-serif; font-size: 3rem; font-weight: 800;
        background: linear-gradient(90deg, #a78bfa, #f472b6);
        -webkit-background-clip: text; -webkit-text-fill-color: transparent;
        margin-bottom: 5px; animation: fadeUp 0.5s ease;
      }
      .hero-sub { color: #b8b8dc; font-size: 1rem; margin-bottom: 20px; font-weight: 300; }

      .social-links { display: flex; justify-content: center; gap: 12px; margin-bottom: 28px; }
      .social-links a {
        display: inline-flex; align-items: center; gap: 6px; border-radius: 20px;
        padding: 6px 16px; text-decoration: none; font-size: 0.82rem; transition: all 0.2s;
      }
      .social-links a.github {
        background: rgba(255,255,255,0.07); border: 1px solid rgba(255,255,255,0.12); color: #e8e8f0;
      }
      .social-links a.linkedin {
        background: rgba(0,119,181,0.15); border: 1px solid rgba(0,119,181,0.3); color: #4fa3d1;
      }
      .social-links a:hover { transform: translateY(-1px); }

      .chat-wrap {
        background: rgba(255,255,255,0.03); border: 1px solid rgba(255,255,255,0.08);
        border-radius: 24px; overflow: hidden; backdrop-filter: blur(20px);
      }
      .chat-top-bar { display: flex; justify-content: flex-end; padding: 12px 20px 0; }
      #clear_chat {
        background: transparent !important; border: 1px solid rgba(255,255,255,0.12) !important;
        border-radius: 10px !important; color: #7878a0 !important; padding: 6px 14px !important;
        font-family: 'DM Sans', sans-serif !important; font-size: 0.8rem !important;
        cursor: pointer !important; transition: all 0.2s !important;
      }
      #clear_chat:hover { border-color: rgba(255,100,100,0.4) !important; color: #ff8080 !important; }

      .chat-messages {
        height: 460px; overflow-y: auto; padding: 20px 30px 30px;
        display: flex; flex-direction: column; gap: 20px; scroll-behavior: smooth;
      }
      .chat-messages::-webkit-scrollbar { width: 4px; }
      .chat-messages::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.1); border-radius: 4px; }

      .empty-state {
        display: flex; flex-direction: column; align-items: center;
        justify-content: center; height: 100%; gap: 14px; color: #4a4a6a; text-align: center;
      }
      .empty-state .big-text {
        font-family: 'Syne', sans-serif; font-size: 1.5rem; font-weight: 600; color: #c0b0f0;
      }

      .msg-row { display: flex; gap: 12px; align-items: flex-end; animation: fadeIn 0.3s ease both; }
      .msg-row.user { flex-direction: row-reverse; }

      .msg-avatar {
        width: 32px; height: 32px; border-radius: 50%; display: flex;
        align-items: center; justify-content: center; font-size: 14px; flex-shrink: 0;
      }
      .msg-avatar.agent { background: linear-gradient(135deg, #633cff, #a78bfa); }
      .msg-avatar.user  { background: rgba(255,255,255,0.1); }

      .msg-bubble {
        max-width: 80%; padding: 14px 18px; border-radius: 20px; line-height: 1.7; font-size: 0.95rem;
      }
      .msg-bubble.agent {
        background: rgba(99,60,255,0.12); border: 1px solid rgba(167,139,250,0.2);
        color: #e8e8ff; border-bottom-left-radius: 4px;
      }
      .msg-bubble.agent strong { color: #ffffff; font-weight: 700; }
      .msg-bubble.agent ul { margin-left: 20px; margin-top: 8px; margin-bottom: 4px; }
      .msg-bubble.agent ol { margin-left: 20px; margin-top: 8px; margin-bottom: 4px; }
      .msg-bubble.agent li { margin-bottom: 6px; color: #d1d1f0; }
      .msg-bubble.agent p  { margin-bottom: 8px; }
      .msg-bubble.agent p:last-child { margin-bottom: 0; }
      .msg-bubble.agent h3 { color: #ffffff; font-size: 0.97rem; font-weight: 700; margin: 10px 0 4px; }
      .msg-bubble.user {
        background: rgba(255,255,255,0.08); border: 1px solid rgba(255,255,255,0.1);
        text-align: right; border-bottom-right-radius: 4px; color: #ffffff;
      }

      /* Typing indicator */
      .typing-row { display: flex; gap: 12px; align-items: flex-end; }
      .typing-bubble {
        background: rgba(99,60,255,0.12); border: 1px solid rgba(167,139,250,0.2);
        border-radius: 20px; border-bottom-left-radius: 4px;
        padding: 14px 18px; display: flex; gap: 5px; align-items: center;
      }
      .typing-dot {
        width: 7px; height: 7px; background: #a78bfa;
        border-radius: 50%; animation: typingBounce 1.2s infinite;
      }
      .typing-dot:nth-child(2) { animation-delay: 0.2s; }
      .typing-dot:nth-child(3) { animation-delay: 0.4s; }

      .input-area {
        padding: 16px 20px; border-top: 1px solid rgba(255,255,255,0.07);
        display: flex; gap: 12px; background: rgba(0,0,0,0.3); align-items: flex-end;
      }
      .input-area .form-group { margin: 0 !important; flex: 1; }
      #user_input {
        width: 100% !important; background: rgba(255,255,255,0.06) !important;
        border: 1px solid rgba(255,255,255,0.1) !important; border-radius: 14px !important;
        color: white !important; padding: 14px 16px !important; outline: none !important;
        font-size: 1rem !important; font-family: 'DM Sans', sans-serif !important;
        transition: border-color 0.2s !important; line-height: 1.5 !important;
        resize: none !important; overflow: hidden !important; max-height: 140px !important;
        display: block !important;
      }
      #user_input:focus { border-color: rgba(99,60,255,0.5) !important; box-shadow: 0 0 0 3px rgba(99,60,255,0.08) !important; }
      #user_input::placeholder { color: #b0b0cc !important; font-size: 1.02rem !important; }
      #send {
        background: linear-gradient(135deg, #633cff, #4f2fcc) !important; border: none !important;
        border-radius: 14px !important; color: white !important; padding: 14px 24px !important;
        font-weight: 600 !important; cursor: pointer !important; white-space: nowrap !important;
        font-family: 'DM Sans', sans-serif !important; font-size: 0.95rem !important;
        transition: all 0.2s !important;
      }
      #send:hover { transform: translateY(-1px) !important; box-shadow: 0 4px 20px rgba(99,60,255,0.4) !important; }

      .footer { text-align: center; margin-top: 24px; color: #3a3a5a; font-size: 0.78rem; }

      @keyframes fadeUp  { from { opacity:0; transform:translateY(20px); } to { opacity:1; transform:translateY(0); } }
      @keyframes fadeIn  { from { opacity:0; transform:translateY(8px);  } to { opacity:1; transform:translateY(0); } }
      @keyframes typingBounce { 0%,60%,100% { transform:translateY(0); } 30% { transform:translateY(-6px); } }
    "))
  ),
  
  div(class = "page-wrap",
      uiOutput("current_view"),
      div(class = "footer", uiOutput("footer_text"))
  ),
  
  tags$script(HTML("
    // Enter to submit name
    $(document).on('keypress', '#visitor_name', function(e) {
      if (e.which === 13) { e.preventDefault(); $('#start_chat').click(); }
    });

    // Enter = send, Shift+Enter = new line
    $(document).on('keydown', '#user_input', function(e) {
      if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        var val = $(this).val().trim();
        if (!val) return;
        Shiny.setInputValue('user_input', val, {priority: 'event'});
        $(this).val('').css('height', 'auto');
        setTimeout(function() { $('#send').click(); }, 50);
      }
    });

    // Auto-resize textarea
    $(document).on('input', '#user_input', function() {
      this.style.height = 'auto';
      this.style.height = Math.min(this.scrollHeight, 140) + 'px';
    });

    function focusInput() {
      setTimeout(function() {
        var inp = document.getElementById('user_input');
        if (inp) inp.focus();
      }, 120);
    }

    function scrollToBottom() {
      var el = document.getElementById('chat_messages');
      if (el) el.scrollTop = el.scrollHeight;
    }

    Shiny.addCustomMessageHandler('focusInput',   function(msg) { focusInput(); });
    Shiny.addCustomMessageHandler('scrollBottom', function(msg) { scrollToBottom(); });

    // MutationObserver: auto-scroll + refocus on every render
    var chatObserver = new MutationObserver(function() { scrollToBottom(); });

    $(document).on('shiny:value', function() {
      setTimeout(function() {
        var target = document.getElementById('chat_messages');
        if (target) {
          chatObserver.disconnect();
          chatObserver.observe(target, { childList: true, subtree: true, characterData: true });
          scrollToBottom();
        }
        focusInput();
      }, 100);
    });
  "))
)

# ── SERVER ──
server <- function(input, output, session) {
  
  chat <- chat_mistral(model = "mistral-small")
  chat$chat(paste0(
    "You are Ditiro Letsoalo's personal AI assistant. ",
    "Speak confidently about him as if you know him personally. ",
    "Never say 'according to his CV', 'based on his CV', or 'from his CV'. Speak naturally.\n\n",
    "Background information about Ditiro:\n\n", cv_text,
    "\n\n--- MORE ABOUT DITIRO ---\n\n",
    "HIGH SCHOOL:\n",
    "- School: Kgalema Senior Secondary School\n",
    "- Location: Mafefe village, Limpopo, South Africa\n",
    "- Matric year: 2019\n",
    "- Subjects: Mathematics, Physical Sciences, English First Additional Language, ",
    "Sepedi Home Language, Life Orientation, Life Sciences, Geography\n",
    "- IMPORTANT: Do NOT reveal his matric average or any marks.\n\n",
    "POSTGRADUATE STUDIES:\n",
    "- Currently in his 2nd year of a Masters degree (2026)\n",
    "- Research title: Prediction of Extreme Events using Bayesian Forecasting\n",
    "- Focus: Predicting floods as extreme weather events\n",
    "- IMPORTANT: Do NOT reveal his degree average, GPA, or any marks.\n\n",
    "PHOTO:\n",
    "- If asked for a photo, respond with SHOW_PHOTO on its own line, then a friendly message.\n\n",
    "LANGUAGES: Sesotho, Sepedi, Setswana, English\n\n",
    "FUN FACT: Ditiro loves playing football but does not watch it\n\n",
    "CONTACT:\n",
    "- GitHub: https://github.com/ditiroletsoalo\n",
    "- LinkedIn: https://www.linkedin.com/in/ditiro-letsoalo-3b908722a/\n\n",
    "GENERAL RULES:\n",
    "- ONLY answer questions about Ditiro. Politely redirect anything else.\n",
    "- Never reveal academic marks or averages.\n",
    "- Use **bold** and bullet points to format longer answers.\n",
    "- Be warm, professional and enthusiastic.\n",
    "- Remember the visitor name when told and use it naturally.\n",
    "- If asked who the visitor is or their name, tell them their name.\n"
  ))
  
  history      <- reactiveVal(list())
  waiting      <- reactiveVal(FALSE)
  visitor_name <- reactiveVal(NULL)
  
  observeEvent(input$start_chat, {
    name <- trimws(input$visitor_name)
    if (nchar(name) > 0) {
      visitor_name(name)
      chat$chat(paste0(
        "VISITOR INFO: The person chatting is called ", name, ". ",
        "Remember this name. If they ask who they are or what their name is, tell them: ", name, "."
      ))
    }
  })
  
  observeEvent(input$clear_chat, {
    history(list())
    waiting(FALSE)
    session$sendCustomMessage("focusInput", list())
  })
  
  observeEvent(input$send, {
    req(input$user_input, nchar(trimws(input$user_input)) > 0)
    
    user_msg <- trimws(input$user_input)
    updateTextInput(session, "user_input", value = "")
    session$sendCustomMessage("focusInput", list())
    
    history(c(history(), list(list(role = "user", text = user_msg))))
    waiting(TRUE)
    session$sendCustomMessage("scrollBottom", list())
    
    response <- tryCatch(
      chat$chat(user_msg),
      error = function(e) "Sorry, something went wrong. Please try again."
    )
    
    waiting(FALSE)
    
    if (grepl("SHOW_PHOTO", response)) {
      clean <- trimws(gsub("SHOW_PHOTO", "", response))
      history(c(history(), list(list(role = "agent", text = clean, photo = TRUE))))
      later::later(function() { session$sendCustomMessage("scrollBottom", list()) }, 0.4)
    } else {
      history(c(history(), list(list(role = "agent", text = response, photo = FALSE))))
      session$sendCustomMessage("scrollBottom", list())
    }
    
    session$sendCustomMessage("focusInput", list())
  })
  
  output$current_view <- renderUI({
    
    if (is.null(visitor_name())) {
      return(
        div(class = "welcome-screen",
            div(style = "font-size:3rem; margin-bottom:16px;", "\U0001f44b"),
            tags$h2("Connect with Ditiro"),
            tags$p("Data Science \u00b7 BI Engineering \u00b7 Bayesian Research"),
            div(class = "name-input-wrap",
                tags$input(id = "visitor_name", type = "text", placeholder = "What's your name?"),
                actionButton("start_chat", "Let's Talk \u2192")
            )
        )
      )
    }
    
    h <- as.integer(format(Sys.time(), "%H"))
    greet <- if (h >= 5 && h < 12) "Good Morning"
    else if (h >= 12 && h < 17) "Good Afternoon"
    else if (h >= 17 && h < 21) "Good Evening"
    else "Hey"
    
    msgs       <- history()
    is_waiting <- waiting()
    
    if (length(msgs) == 0 && !is_waiting) {
      chat_content <- div(class = "empty-state",
                          div(style = "font-size:2rem; opacity:0.4;", "\U0001f4ac"),
                          div(class = "big-text", "Ask me anything about Ditiro!")
      )
    } else {
      bubbles <- lapply(msgs, function(m) {
        if (m$role == "user") {
          div(class = "msg-row user",
              div(class = "msg-avatar user", "\U0001f464"),
              div(class = "msg-bubble user", m$text)
          )
        } else if (isTRUE(m$photo)) {
          div(class = "msg-row agent",
              div(class = "msg-avatar agent", "\u2736"),
              div(class = "msg-bubble agent",
                  tags$img(src = "ditiro.jpg",
                           style = "width:180px; height:180px; object-fit:cover; border-radius:12px; display:block; margin-bottom:8px;"),
                  if (nchar(trimws(m$text)) > 0) div(m$text)
              )
          )
        } else {
          div(class = "msg-row agent",
              div(class = "msg-avatar agent", "\u2736"),
              div(class = "msg-bubble agent",
                  HTML(commonmark::markdown_html(m$text))
              )
          )
        }
      })
      
      if (is_waiting) {
        bubbles <- c(bubbles, list(
          div(class = "typing-row",
              div(class = "msg-avatar agent", "\u2736"),
              div(class = "typing-bubble",
                  div(class = "typing-dot"),
                  div(class = "typing-dot"),
                  div(class = "typing-dot")
              )
          )
        ))
      }
      chat_content <- bubbles
    }
    
    div(
      div(class = "hero", style = "text-align:center; margin-bottom:10px;",
          div(class = "big-greeting", paste0(greet, ", ", visitor_name(), "!")),
          div(class = "hero-sub", "Ask me anything about Ditiro's journey."),
          div(class = "social-links",
              tags$a(href = "https://github.com/ditiroletsoalo",
                     target = "_blank", class = "github", tags$span("\u2395"), "GitHub"),
              tags$a(href = "https://www.linkedin.com/in/ditiro-letsoalo-3b908722a/",
                     target = "_blank", class = "linkedin", tags$span("in"), "LinkedIn")
          )
      ),
      div(class = "chat-wrap",
          div(class = "chat-top-bar",
              actionButton("clear_chat", "\u21ba Clear Chat")
          ),
          div(class = "chat-messages", id = "chat_messages", chat_content),
          div(class = "input-area",
              div(class = "form-group",
                  tags$textarea(id = "user_input", class = "form-control", rows = "1",
                                placeholder = "Ask me anything about Ditiro!")
              ),
              actionButton("send", "Send \u2191")
          )
      )
    )
  })
  
  output$footer_text <- renderUI({
    if (!is.null(visitor_name())) tags$span("Powered by Mistral AI \u00b7 Built with R Shiny")
  })
}

shinyApp(ui, server)