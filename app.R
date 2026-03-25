if (file.exists("secrets.R")) source("secrets.R")

library(shiny)
library(ellmer)
library(pdftools)

cv_text <- paste(pdf_text("Letsoalo_Ditiro_CV.pdf"), collapse = "\n")

# Make photo available as static asset
if (!dir.exists("www")) dir.create("www")
if (file.exists("ditiro.jpg")) file.copy("ditiro.jpg", "www/ditiro.jpg", overwrite = TRUE)


ui <- fluidPage(
  tags$head(
    tags$link(rel = "preconnect", href = "https://fonts.googleapis.com"),
    tags$link(rel = "stylesheet", href = "https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=DM+Sans:wght@300;400;500&display=swap"),
    tags$style(HTML("

      * { box-sizing: border-box; margin: 0; padding: 0; }

      body {
        background-color: #0a0a0f;
        background-image:
          radial-gradient(ellipse at 20% 50%, rgba(99, 60, 255, 0.12) 0%, transparent 50%),
          radial-gradient(ellipse at 80% 20%, rgba(0, 210, 190, 0.08) 0%, transparent 50%);
        font-family: 'DM Sans', sans-serif;
        color: #e8e8f0;
        min-height: 100vh;
      }

      .container-fluid { padding: 0 !important; }

      /* ── LAYOUT ── */
      .page-wrap {
        max-width: 780px;
        margin: 0 auto;
        padding: 48px 24px 80px;
      }

      /* ── HEADER ── */
      .hero {
        text-align: center;
        margin-bottom: 40px;
        animation: fadeUp 0.7s ease both;
      }

      .avatar-ring {
        display: inline-block;
        padding: 3px;
        background: linear-gradient(135deg, #633cff, #00d2be);
        border-radius: 50%;
        margin-bottom: 20px;
      }

      .avatar-inner {
        width: 82px;
        height: 82px;
        border-radius: 50%;
        background: #1a1a2e;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 34px;
      }

      .hero h1 {
        font-family: 'Syne', sans-serif;
        font-size: 2.1rem;
        font-weight: 800;
        letter-spacing: -0.03em;
        background: linear-gradient(135deg, #ffffff 30%, #a78bfa);
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
        background-clip: text;
        margin-bottom: 6px;
      }

      .hero-sub {
        font-size: 0.95rem;
        color: #7878a0;
        font-weight: 300;
        letter-spacing: 0.04em;
        text-transform: uppercase;
      }

      .status-dot {
        display: inline-flex;
        align-items: center;
        gap: 7px;
        margin-top: 14px;
        background: rgba(0, 210, 190, 0.1);
        border: 1px solid rgba(0, 210, 190, 0.25);
        border-radius: 20px;
        padding: 5px 14px;
        font-size: 0.78rem;
        color: #00d2be;
        font-weight: 500;
      }

      .status-dot::before {
        content: '';
        width: 7px;
        height: 7px;
        background: #00d2be;
        border-radius: 50%;
        animation: pulse 2s infinite;
      }

      /* ── CHAT BOX ── */
      .chat-wrap {
        background: rgba(255,255,255,0.03);
        border: 1px solid rgba(255,255,255,0.08);
        border-radius: 20px;
        overflow: hidden;
        animation: fadeUp 0.7s 0.15s ease both;
        backdrop-filter: blur(12px);
      }

      .chat-messages {
        height: 420px;
        overflow-y: auto;
        padding: 28px 24px;
        display: flex;
        flex-direction: column;
        gap: 16px;
        scroll-behavior: smooth;
      }

      .chat-messages::-webkit-scrollbar { width: 4px; }
      .chat-messages::-webkit-scrollbar-track { background: transparent; }
      .chat-messages::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.1); border-radius: 4px; }

      /* ── MESSAGES ── */
      .msg-row {
        display: flex;
        align-items: flex-end;
        gap: 10px;
        animation: msgIn 0.3s ease both;
      }

      .msg-row.user { flex-direction: row-reverse; }

      .msg-avatar {
        width: 30px;
        height: 30px;
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 14px;
        flex-shrink: 0;
      }

      .msg-avatar.agent { background: linear-gradient(135deg, #633cff, #00d2be); }
      .msg-avatar.user  { background: rgba(255,255,255,0.1); }

      .msg-bubble {
        max-width: 72%;
        padding: 12px 16px;
        border-radius: 18px;
        font-size: 0.92rem;
        line-height: 1.6;
        font-weight: 400;
      }

      .msg-bubble.agent {
        background: rgba(99, 60, 255, 0.15);
        border: 1px solid rgba(99, 60, 255, 0.25);
        border-bottom-left-radius: 5px;
        color: #e0e0f5;
      }

      .msg-bubble.user {
        background: rgba(255,255,255,0.08);
        border: 1px solid rgba(255,255,255,0.1);
        border-bottom-right-radius: 5px;
        color: #e8e8f0;
        text-align: right;
      }

      /* ── TYPING INDICATOR ── */
      .typing-row {
        display: flex;
        align-items: flex-end;
        gap: 10px;
      }

      .typing-bubble {
        background: rgba(99, 60, 255, 0.15);
        border: 1px solid rgba(99, 60, 255, 0.25);
        border-radius: 18px;
        border-bottom-left-radius: 5px;
        padding: 14px 18px;
        display: flex;
        gap: 5px;
        align-items: center;
      }

      .typing-dot {
        width: 7px; height: 7px;
        background: #a78bfa;
        border-radius: 50%;
        animation: typingBounce 1.2s infinite;
      }
      .typing-dot:nth-child(2) { animation-delay: 0.2s; }
      .typing-dot:nth-child(3) { animation-delay: 0.4s; }

      /* ── EMPTY STATE ── */
      .empty-state {
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        height: 100%;
        gap: 12px;
        color: #4a4a6a;
        text-align: center;
      }

      .empty-state .icon { font-size: 2.5rem; opacity: 0.5; }

      .empty-state p {
        font-size: 0.9rem;
        line-height: 1.6;
        max-width: 300px;
      }

      .suggestion-chips {
        display: flex;
        flex-wrap: wrap;
        gap: 8px;
        justify-content: center;
        margin-top: 8px;
      }

      .chip {
        background: rgba(99,60,255,0.1);
        border: 1px solid rgba(99,60,255,0.2);
        color: #a78bfa;
        padding: 6px 14px;
        border-radius: 20px;
        font-size: 0.8rem;
        cursor: pointer;
        transition: all 0.2s;
      }

      .chip:hover {
        background: rgba(99,60,255,0.22);
        border-color: rgba(99,60,255,0.4);
        transform: translateY(-1px);
      }

      /* ── INPUT AREA ── */
      .input-area {
        padding: 16px 20px;
        border-top: 1px solid rgba(255,255,255,0.07);
        display: flex;
        gap: 10px;
        align-items: center;
        background: rgba(0,0,0,0.2);
      }

      .input-area .form-group { margin: 0 !important; flex: 1; }

      #user_input {
        width: 100% !important;
        background: rgba(255,255,255,0.06) !important;
        border: 1px solid rgba(255,255,255,0.1) !important;
        border-radius: 12px !important;
        color: #e8e8f0 !important;
        padding: 12px 16px !important;
        font-family: 'DM Sans', sans-serif !important;
        font-size: 0.92rem !important;
        outline: none !important;
        transition: border-color 0.2s !important;
      }

      #user_input:focus {
        border-color: rgba(99,60,255,0.5) !important;
        box-shadow: 0 0 0 3px rgba(99,60,255,0.08) !important;
      }

      #user_input::placeholder { color: #4a4a6a !important; }

      #send {
        background: linear-gradient(135deg, #633cff, #4f2fcc) !important;
        border: none !important;
        border-radius: 12px !important;
        color: white !important;
        padding: 12px 20px !important;
        font-family: 'DM Sans', sans-serif !important;
        font-weight: 500 !important;
        font-size: 0.9rem !important;
        cursor: pointer !important;
        transition: all 0.2s !important;
        white-space: nowrap;
      }

      #send:hover {
        transform: translateY(-1px) !important;
        box-shadow: 0 4px 20px rgba(99,60,255,0.4) !important;
      }

      #send:active { transform: translateY(0) !important; }

      /* ── FOOTER ── */
      .footer {
        text-align: center;
        margin-top: 24px;
        color: #3a3a5a;
        font-size: 0.78rem;
        animation: fadeUp 0.7s 0.3s ease both;
      }

      /* ── ANIMATIONS ── */
      @keyframes fadeUp {
        from { opacity: 0; transform: translateY(20px); }
        to   { opacity: 1; transform: translateY(0); }
      }

      @keyframes msgIn {
        from { opacity: 0; transform: translateY(8px); }
        to   { opacity: 1; transform: translateY(0); }
      }

      @keyframes typingBounce {
        0%, 60%, 100% { transform: translateY(0); }
        30%            { transform: translateY(-6px); }
      }

      @keyframes pulse {
        0%, 100% { opacity: 1; }
        50%       { opacity: 0.4; }
      }
    "))
  ),
  
  div(class = "page-wrap",
      
      # ── HEADER ──
      div(class = "hero",
          div(class = "avatar-ring",
              div(class = "avatar-inner", "👨🏾‍💻")
          ),
          tags$h1("Ditiro Letsoalo"),
          div(class = "hero-sub", "Data Scientist & Developer"),
          div(class = "status-dot", "Available for opportunities"),
          br(),
          div(style = "display:flex; justify-content:center; gap:16px; margin-top:10px;",
              tags$a(href = "https://github.com/ditiroletsoalo", target = "_blank",
                     style = "display:inline-flex; align-items:center; gap:6px; background:rgba(255,255,255,0.07); border:1px solid rgba(255,255,255,0.12); border-radius:20px; padding:6px 16px; color:#e8e8f0; text-decoration:none; font-size:0.82rem; transition:all 0.2s;",
                     tags$span("⌥"), "GitHub"
              ),
              tags$a(href = "https://www.linkedin.com/in/ditiro-letsoalo-3b908722a/", target = "_blank",
                     style = "display:inline-flex; align-items:center; gap:6px; background:rgba(0,119,181,0.15); border:1px solid rgba(0,119,181,0.3); border-radius:20px; padding:6px 16px; color:#4fa3d1; text-decoration:none; font-size:0.82rem; transition:all 0.2s;",
                     tags$span("in"), "LinkedIn"
              )
          )
      ),
      
      # ── CHAT ──
      div(class = "chat-wrap",
          div(class = "chat-messages", id = "chat_messages",
              uiOutput("chat_history")
          ),
          div(class = "input-area",
              div(class = "form-group",
                  tags$input(
                    id = "user_input",
                    type = "text",
                    class = "form-control",
                    placeholder = "Ask me about Ditiro's skills, experience, projects..."
                  )
              ),
              actionButton("send", "Send ↑")
          )
      ),
      
      # ── FOOTER ──
      div(class = "footer",
          "Powered by Mistral AI · Built with R Shiny"
      )
  ),
  
  # ── JS: Enter to send + chip clicks + auto-scroll ──
  tags$script(HTML("
    $(document).on('keypress', '#user_input', function(e) {
      if (e.which == 13) {
        e.preventDefault();
        var val = $(this).val();
        if (val.trim() === '') return;
        Shiny.setInputValue('user_input', val, {priority: 'event'});
        setTimeout(function() { $('#send').click(); }, 50);
      }
    });

    $(document).on('click', '.chip', function() {
      var txt = $(this).text();
      $('#user_input').val(txt);
      Shiny.setInputValue('user_input', txt, {priority: 'event'});
      setTimeout(function() { $('#send').click(); }, 50);
    });

    Shiny.addCustomMessageHandler('scrollBottom', function(msg) {
      var el = document.getElementById('chat_messages');
      if (el) el.scrollTop = el.scrollHeight;
    });

    Shiny.addCustomMessageHandler('animateLastAgent', function(msg) {
      setTimeout(function() {
        var bubbles = document.querySelectorAll('.msg-bubble.agent');
        if (!bubbles.length) return;
        var last = bubbles[bubbles.length - 1];
        var fullText = last.textContent;
        last.textContent = '';
        var i = 0;
        var el = document.getElementById('chat_messages');
        function typeNext() {
          if (i < fullText.length) {
            last.textContent += fullText[i];
            i++;
            el.scrollTop = el.scrollHeight;
            setTimeout(typeNext, 8);
          }
        }
        typeNext();
      }, 20);
    });
  "))
)

server <- function(input, output, session) {
  
  chat <- chat_mistral(model = "mistral-small")
  chat$chat(paste0(
    "You are a friendly, confident assistant representing Ditiro Letsoalo. ",
    "Here is his CV:\n\n", cv_text,
    
    "\n\n--- ADDITIONAL PERSONAL INFORMATION ---\n\n",
    
    "HIGH SCHOOL:\n",
    "- School: Kgalema Senior Secondary School\n",
    "- Location: Mafefe village, Limpopo, South Africa\n",
    "- Matric year: 2019\n",
    "- Subjects: Mathematics, Physical Sciences, English First Additional Language, ",
    "Sepedi Home Language, Life Orientation, Life Sciences, Geography\n",
    "- IMPORTANT: Do NOT share or reveal his matric average or any marks if asked.\n\n",
    
    "POSTGRADUATE STUDIES:\n",
    "- Currently in his 2nd year of a Master's degree (2026)\n",
    "- Research title: Prediction of Extreme Events using Bayesian Forecasting\n",
    "- Focus: Predicting floods as extreme weather events\n",
    "- IMPORTANT: Do NOT share or reveal his degree average, GPA, or any academic marks if asked.\n\n",
    
    "PHOTO:\n",
    "- If anyone asks for a photo or picture of Ditiro, respond with exactly this token on its own line: SHOW_PHOTO\n",
    "- Then add a friendly line like: Here is a photo of Ditiro!\n\n",
    
    "LANGUAGES SPOKEN:\n",
    "- Sotho (Sesotho)\n",
    "- Sepedi\n",
    "- Setswana\n",
    "- English\n\n",
    
    "FUN FACT:\n",
    "- Ditiro loves playing football but does not watch it\n\n",
    
    "CONTACT & SOCIAL:\n",
    "- GitHub: https://github.com/ditiroletsoalo\n",
    "- LinkedIn: https://www.linkedin.com/in/ditiro-letsoalo-3b908722a/\n",
    "- When asked for links, ALWAYS include the full URLs exactly as written above so they become clickable.\n\n",
    
    "OTHER USEFUL INFO:\n",
    "- Originally from Mafefe, a small village in Limpopo, South Africa\n",
    "- His Masters research addresses real-world challenges: predicting floods using Bayesian statistical methods\n",
    "- He is multilingual, which reflects his diverse background\n",
    "- He is open to opportunities in data science, statistics, and research\n\n",
    
    "GENERAL RULES:\n",
    "- Never reveal any academic averages, marks, percentages or grades (matric or university)\n",
    "- If asked about marks/grades, politely say that information is private\n",
    "- Be warm, professional and enthusiastic about his work and background\n",
    "- If asked something not covered here or in the CV, encourage them to reach out to Ditiro directly\n"
  ))
  
  history  <- reactiveVal(list())
  waiting  <- reactiveVal(FALSE)
  
  observeEvent(input$send, {
    req(input$user_input, nchar(trimws(input$user_input)) > 0)
    
    user_msg <- trimws(input$user_input)
    updateTextInput(session, "user_input", value = "")
    
    history(c(history(), list(list(role = "user", text = user_msg))))
    waiting(TRUE)
    session$sendCustomMessage("scrollBottom", list())
    
    response <- tryCatch(
      chat$chat(user_msg),
      error = function(e) "Sorry, something went wrong. Please try again."
    )
    
    waiting(FALSE)
    
    # Check if agent wants to show photo
    if (grepl("SHOW_PHOTO", response)) {
      clean_response <- trimws(gsub("SHOW_PHOTO", "", response))
      history(c(history(), list(list(role = "agent", text = clean_response, photo = TRUE))))
    } else {
      history(c(history(), list(list(role = "agent", text = response, photo = FALSE))))
    }
    session$sendCustomMessage("animateLastAgent", list())
  })
  
  output$chat_history <- renderUI({
    
    msgs <- history()
    is_waiting <- waiting()
    
    if (length(msgs) == 0 && !is_waiting) {
      return(
        div(class = "empty-state",
            div(class = "icon", "💬"),
            tags$p("Ask anything about Ditiro — his skills, projects, experience, or background."),
            div(class = "suggestion-chips",
                div(class = "chip", "What are your skills?"),
                div(class = "chip", "Tell me about your experience"),
                div(class = "chip", "What projects have you worked on?"),
                div(class = "chip", "Are you open to work?")
            )
        )
      )
    }
    
    bubbles <- lapply(msgs, function(m) {
      if (m$role == "user") {
        div(class = "msg-row user",
            div(class = "msg-avatar user", "👤"),
            div(class = "msg-bubble user", m$text)
        )
      } else {
        if (isTRUE(m$photo)) {
          div(class = "msg-row agent",
              div(class = "msg-avatar agent", "✦"),
              div(class = "msg-bubble agent",
                  tags$img(src = "ditiro.jpg", style = "width:180px; height:180px; object-fit:cover; border-radius:12px; display:block; margin-bottom:8px;"),
                  if (nchar(trimws(m$text)) > 0) div(m$text)
              )
          )
        } else {
          div(class = "msg-row agent",
              div(class = "msg-avatar agent", "✦"),
              div(class = "msg-bubble agent", m$text)
          )
        }
      }
    })
    
    if (is_waiting) {
      bubbles <- c(bubbles, list(
        div(class = "typing-row",
            div(class = "msg-avatar agent", "✦"),
            div(class = "typing-bubble",
                div(class = "typing-dot"),
                div(class = "typing-dot"),
                div(class = "typing-dot")
            )
        )
      ))
    }
    
    bubbles
  })
}

shinyApp(ui, server)