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
      .msg-bubble.agent strong { color: #ffffff; font-weight: 700; }
      .msg-bubble.agent ul { margin-left: 20px; margin-top: 8px; }
      .msg-bubble.agent li { margin-bottom: 6px; color: #d1d1f0; }
      .msg-bubble.agent p  { margin-bottom: 8px; }
      .msg-bubble.agent p:last-child { margin-bottom: 0; }
      .msg-bubble.user { background: rgba(255,255,255,0.08); border: 1px solid rgba(255,255,255,0.1); text-align: right; border-bottom-right-radius: 4px; color: #ffffff; }

      .typing-bubble { background: rgba(99,60,255,0.12); border: 1px solid rgba(167,139,250,0.2); border-radius: 20px; border-bottom-left-radius: 4px; padding: 14px 18px; display: flex; gap: 5px; }
      .typing-dot { width: 7px; height: 7px; background: #a78bfa; border-radius: 50%; animation: typingBounce 1.2s infinite; }
      .typing-dot:nth-child(2) { animation-delay: 0.2s; }
      .typing-dot:nth-child(3) { animation-delay: 0.4s; }

      .input-area { padding: 16px 20px; border-top: 1px solid rgba(255,255,255,0.07); display: flex; gap: 10px; background: rgba(0,0,0,0.3); align-items: flex-end; }
      .input-area .form-group { margin: 0 !important; flex: 1; }
      #user_input {
        width: 100% !important; background: rgba(255,255,255,0.06) !important;
        border: 1px solid rgba(255,255,255,0.1) !important; border-radius: 14px !important;
        color: white !important; padding: 14px 16px !important; outline: none !important;
        resize: none !important; max-height: 140px !important; font-size: 1rem !important;
        font-family: 'DM Sans', sans-serif !important; line-height: 1.5 !important;
      }
      #user_input::placeholder { color: #b0b0cc !important; font-size: 1.02rem !important; }
      #user_input:focus { border-color: rgba(99,60,255,0.5) !important; }

      #send {
        background: linear-gradient(135deg, #633cff, #4f2fcc) !important; border: none !important;
        border-radius: 14px !important; color: white !important; padding: 14px 22px !important;
        font-weight: 600 !important; cursor: pointer !important; white-space: nowrap !important;
        font-family: 'DM Sans', sans-serif !important; font-size: 0.95rem !important;
        transition: all 0.2s !important;
      }
      #send:hover { transform: translateY(-1px) !important; box-shadow: 0 4px 20px rgba(99,60,255,0.4) !important; }

      /* ── MIC BUTTON ── */
      #mic_btn {
        background: rgba(255,255,255,0.06) !important;
        border: 1px solid rgba(255,255,255,0.15) !important;
        border-radius: 14px !important; color: #a78bfa !important;
        padding: 14px 16px !important; cursor: pointer !important;
        font-size: 1.1rem !important; line-height: 1 !important;
        transition: all 0.2s !important; flex-shrink: 0 !important;
      }
      #mic_btn:hover { background: rgba(167,139,250,0.15) !important; border-color: rgba(167,139,250,0.4) !important; }
      #mic_btn.listening {
        background: rgba(255,80,80,0.15) !important;
        border-color: rgba(255,80,80,0.5) !important;
        color: #ff6060 !important;
        animation: micPulse 1s infinite !important;
      }
      @keyframes micPulse {
        0%, 100% { box-shadow: 0 0 0 0 rgba(255,80,80,0.3); }
        50%       { box-shadow: 0 0 0 8px rgba(255,80,80,0); }
      }

      .footer { text-align: center; margin-top: 24px; color: #3a3a5a; font-size: 0.78rem; }
      @keyframes fadeUp  { from { opacity:0; transform:translateY(20px); } to { opacity:1; transform:translateY(0); } }
      @keyframes fadeIn  { from { opacity:0; transform:translateY(8px);  } to { opacity:1; transform:translateY(0); } }
      @keyframes typingBounce { 0%,60%,100% { transform:translateY(0); } 30% { transform:translateY(-6px); } }
    "))
  ),
  div(class = "page-wrap", uiOutput("current_view"), div(class = "footer", uiOutput("footer_text"))),
  tags$script(HTML("
    // ── Name field: Enter to proceed ──
    $(document).on('keypress', '#visitor_name', function(e) {
      if (e.which === 13) { e.preventDefault(); $('#start_chat').click(); }
    });

    // ── Chat input: Enter = send, Shift+Enter = new line ──
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

    // ── Auto-resize textarea ──
    $(document).on('input', '#user_input', function() {
      this.style.height = 'auto';
      this.style.height = Math.min(this.scrollHeight, 140) + 'px';
    });

    // ── Scroll & focus helpers ──
    Shiny.addCustomMessageHandler('scrollBottom', function(msg) {
      setTimeout(function() {
        var el = document.getElementById('chat_messages');
        if (el) el.scrollTop = el.scrollHeight;
      }, 150);
    });

    Shiny.addCustomMessageHandler('focusInput', function(msg) {
      setTimeout(function() {
        var inp = document.getElementById('user_input');
        if (inp) inp.focus();
      }, 120);
    });

    // ── MICROPHONE (Web Speech API) ──
    var recognition = null;
    var isListening  = false;

    $(document).on('click', '#mic_btn', function() {
      // Check browser support
      var SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
      if (!SpeechRecognition) {
        alert('Sorry, your browser does not support voice input. Try Chrome or Edge.');
        return;
      }

      if (isListening) {
        // Stop listening
        recognition.stop();
        return;
      }

      // Start listening
      recognition = new SpeechRecognition();
      recognition.lang        = 'en-US';
      recognition.interimResults = true;
      recognition.maxAlternatives = 1;

      recognition.onstart = function() {
        isListening = true;
        $('#mic_btn').addClass('listening').html('🔴');
      };

      recognition.onresult = function(event) {
        var transcript = '';
        for (var i = event.resultIndex; i < event.results.length; i++) {
          transcript += event.results[i][0].transcript;
        }
        var inp = document.getElementById('user_input');
        if (inp) {
          inp.value = transcript;
          inp.style.height = 'auto';
          inp.style.height = Math.min(inp.scrollHeight, 140) + 'px';
        }
      };

      recognition.onend = function() {
        isListening = false;
        $('#mic_btn').removeClass('listening').html('🎙️');
        // Auto-send if there is text
        var val = $('#user_input').val().trim();
        if (val) {
          Shiny.setInputValue('user_input', val, {priority: 'event'});
          $('#user_input').val('').css('height', 'auto');
          setTimeout(function() { $('#send').click(); }, 100);
        }
      };

      recognition.onerror = function(event) {
        isListening = false;
        $('#mic_btn').removeClass('listening').html('🎙️');
        if (event.error !== 'no-speech') {
          alert('Microphone error: ' + event.error);
        }
      };

      recognition.start();
    });
  "))
)

# ── SERVER LOGIC ──
server <- function(input, output, session) {
  birth_date <- as.Date("2001-03-30")
  today <- Sys.Date()
  ditiro_age <- as.numeric(difftime(today, birth_date, units = "weeks")) %/% 52
  
  chat <- chat_mistral(model = "mistral-small", api_args = list(temperature = 0))
  
  chat$chat(paste0(
    "You are Ditiro Letsoalo's personal AI assistant. Speak confidently and warmly.\n\n",
    
    "── DATE CONTEXT ──\n",
    "Today's Date is: ", format(today, "%A, %B %d, %Y"), "\n",
    "Ditiro's Birthday: March 30, 2001\n",
    if(format(today, "%m-%d") == "03-30") "SPECIAL: Today is Ditiro's birthday! Wish him well if the user mentions it.\n" else "",
    "\n",
    
    "── CONVERSATIONAL ETIQUETTE ──\n",
    "1. If asked 'How are you?' or similar, respond warmly and ALWAYS ask the user how they are doing.\n",
    "2. If asked about the user or their name, respond by explicitly mentioning the user's name.\n",
    "3. NEVER say 'I don't have feelings' or 'I am a virtual assistant'. Keep the persona seamless.\n",
    "4. Keep answers focused on Ditiro's professional journey.\n\n",
    
    "── STRICT TRUTH RULE ──\n",
    "1. You ONLY know facts provided in the background below.\n",
    "2. If asked about something NOT in the text, say: 'I don't have information on that, but I can tell you about his professional journey in Data Science!'\n\n",
    
    "── RICH SKILLS DELIVERY ──\n",
    "When asked about skills, provide deep engaging descriptions with emojis, not just bullet points.\n\n",
    
    "── BACKGROUND DATA ──\n",
    "NAME: Ditiro Letsoalo\n",
    "AGE: ", ditiro_age, " years old.\n",
    "CURRENT ROLE: BI Engineer Graduate at YoYo Rewards (started Feb 2026).\n",
    "ACADEMICS: 2nd Year MSc Statistics at UCT. B.BusSci Analytics (UCT).\n",
    "RESEARCH: 'Prediction of Extreme Events using Bayesian Forecasting' (Focus: Extreme floods).\n",
    "CORE SKILLS: Bayesian Statistics, Business Intelligence, SQL, Amazon QuickSight, Python, R, LaTeX.\n",
    "HIGH SCHOOL: Kgalema Senior Secondary School, Mafefe, Limpopo. Matric 2019.\n",
    "SUBJECTS: Mathematics, Physical Sciences, English FAL, Sepedi HL, Life Orientation, Life Sciences, Geography.\n",
    "LANGUAGES: Sesotho, Sepedi, Setswana, English.\n",
    "FUN FACT: Loves playing football but does not watch it.\n",
    "GITHUB: https://github.com/ditiroletsoalo\n",
    "LINKEDIN: https://www.linkedin.com/in/ditiro-letsoalo-3b908722a/\n\n",
    "CV CONTENT:\n", cv_text,
    "\n\nPHOTO TRIGGER: If asked for a photo, respond ONLY with: SHOW_PHOTO followed by a friendly message.\n\n",
    "IMPORTANT: Never reveal academic averages, marks, percentages or grades.\n",
    "Remember the visitor name when told and use it naturally in conversation.\n",
    "If asked who the visitor is or their name, tell them their name.\n"
  ))
  
  history      <- reactiveVal(list())
  waiting      <- reactiveVal(FALSE)
  visitor_name <- reactiveVal(NULL)
  
  observeEvent(input$start_chat, {
    name <- trimws(input$visitor_name)
    if (nchar(name) > 0) {
      formatted_name <- paste0(toupper(substr(name, 1, 1)), substr(name, 2, nchar(name)))
      visitor_name(formatted_name)
      waiting(TRUE)
      response <- chat$chat(paste0(
        "Visitor's name is ", formatted_name, ". ",
        "Remember this: if they ever ask who they are or what their name is, tell them: ", formatted_name, ". ",
        "Now greet them warmly by name and ask how they are doing today."
      ))
      waiting(FALSE)
      history(c(history(), list(list(role = "agent", text = response, photo = FALSE))))
      session$sendCustomMessage("scrollBottom", list())
      session$sendCustomMessage("focusInput", list())
    }
  })
  
  output$download_cv <- downloadHandler(
    filename = function() { "Letsoalo_Ditiro_CV.pdf" },
    content  = function(file) { if (file.exists("Letsoalo_Ditiro_CV.pdf")) file.copy("Letsoalo_Ditiro_CV.pdf", file) }
  )
  
  observeEvent(input$clear_chat, {
    history(list())
    waiting(FALSE)
    session$sendCustomMessage("focusInput", list())
  })
  
  observeEvent(input$send, {
    req(input$user_input, nchar(trimws(input$user_input)) > 0)
    user_msg <- trimws(input$user_input)
    updateTextInput(session, "user_input", value = "")
    
    history(c(history(), list(list(role = "user", text = user_msg))))
    waiting(TRUE)
    session$sendCustomMessage("scrollBottom", list())
    
    response <- tryCatch(
      chat$chat(user_msg),
      error = function(e) "Sorry, something went wrong. Please try again!"
    )
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
      return(div(class = "welcome-screen",
                 div(style = "font-size:3rem; margin-bottom:16px;", "\U0001f44b"),
                 tags$h2("Connect with Ditiro"),
                 tags$p("BI Engineer @ Yoyo | MSc Candidate (UCT)"),
                 div(class = "name-input-wrap",
                     tags$input(id = "visitor_name", type = "text", placeholder = "What's your name?"),
                     actionButton("start_chat", "Let's Talk \u2192")
                 )
      ))
    }
    
    h     <- as.integer(format(Sys.time(), "%H"))
    greet <- if (h > 3 && h < 12) "Good Morning \U00002600\UFE0F"
    else if (h >= 12 && h < 17) "Good Afternoon \U0001F44B"
    else if (h >= 17 && h < 21) "Good Evening \U0001F306"
    else "Hey there \U0001F319"
    
    msgs       <- history()
    is_waiting <- waiting()
    
    bubbles <- if (length(msgs) == 0 && !is_waiting) {
      div(class = "empty-state",
          div(style = "font-size:2rem; opacity:0.4;", "\U0001f4ac"),
          div(class = "big-text", "Ask me anything about Ditiro!")
      )
    } else {
      bubs <- lapply(msgs, function(m) {
        if (m$role == "user") {
          div(class = "msg-row user",
              div(class = "msg-avatar user", "\U0001f464"),
              div(class = "msg-bubble user", m$text)
          )
        } else {
          if (isTRUE(m$photo)) {
            div(class = "msg-row agent",
                div(class = "msg-avatar agent", "\u2736"),
                div(class = "msg-bubble agent",
                    tags$img(src = "ditiro.jpg",
                             style = "width:180px; height:180px; object-fit:cover; border-radius:12px; display:block; margin-bottom:8px;"),
                    if (nchar(trimws(m$text)) > 0) div(HTML(commonmark::markdown_html(m$text)))
                )
            )
          } else {
            div(class = "msg-row agent",
                div(class = "msg-avatar agent", "\u2736"),
                div(class = "msg-bubble agent", HTML(commonmark::markdown_html(m$text)))
            )
          }
        }
      })
      if (is_waiting) {
        bubs <- c(bubs, list(
          div(class = "msg-row agent",
              div(class = "msg-avatar agent", "\u2736"),
              div(class = "typing-bubble",
                  div(class = "typing-dot"), div(class = "typing-dot"), div(class = "typing-dot")
              )
          )
        ))
      }
      bubs
    }
    
    div(
      div(class = "hero", style = "text-align:center; margin-bottom:10px;",
          div(class = "big-greeting", paste0(greet, ", ", visitor_name(), "!")),
          div(class = "hero-sub", "Ask me anything about Ditiro's journey."),
          div(class = "social-links",
              tags$a(href = "https://github.com/ditiroletsoalo", target = "_blank", class = "github", "\u2395 GitHub"),
              tags$a(href = "https://www.linkedin.com/in/ditiro-letsoalo-3b908722a/", target = "_blank", class = "linkedin", "in LinkedIn"),
              downloadButton("download_cv", "\u21e9 CV", class = "cv-btn")
          )
      ),
      div(class = "chat-wrap",
          div(class = "chat-top-bar", actionButton("clear_chat", "\u21ba Clear Chat")),
          div(class = "chat-messages", id = "chat_messages", bubbles),
          div(class = "input-area",
              div(class = "form-group",
                  tags$textarea(id = "user_input", class = "form-control", rows = "1",
                                placeholder = "Ask me anything about Ditiro!")
              ),
              tags$button(id = "mic_btn", class = "btn", title = "Click to speak", "\U0001f3a4"),
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