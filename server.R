library(auth0)

auth0_server(function(input, output, session) {
  # Read data 
  cs_df <- read.csv('Crime Surveillance System - Survey.csv')
  
  # replacing dots(.) in column names with underscores (_)
  cs_df <- clean_names(cs_df)
  
  # replacing underscores (_) in column names with spaces
  names(cs_df) <- gsub("_", " ", names(cs_df))
  
  # Renaming Columns 
  names(cs_df)[names(cs_df) == "support your above selection"] <- "Yes/No answer reason for: Do you think that alarms sounding off are an effective way to discourage criminal activity?"
  names(cs_df)[names(cs_df) == "support your above selection 1"] <- "Yes/No answer reason for: Do you believe that an automated alert from a surveillance system would improve authority response time?"
  
  # Question selection  
  output$ques <- renderUI({
    varSelectInput("select", label = h4(" "),
                   cs_df[-c(1,5,8,10, 17:20)], selected = cs_df[ncol(cs_df)])
  })
  
  # Question-Response Bar Plot
  output$fig1 <- renderPlotly({
    req(input$select)
    comdata <- cs_df %>% 
      group_by(!!input$select) %>% 
      summarise(n = n()) %>% 
      mutate(pct = n/sum(n), 
             lbl = scales::percent(pct))
    
    cplot <- comdata %>% 
      ggplot(aes(x = reorder(!!input$select, -n), y = n)) +
      geom_bar(fill = "orange",
               stat = "identity") +
      geom_text(aes(label = lbl),
                vjust = -0.25) +
      labs(x = "", y = "",
           title = "") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45))
    
    ggplotly(cplot)
  })
  
  # Text mining function for long response questions  
  tm_crime <- function(or_text) {
    
    # Text Conversion 
    or_text <- iconv(or_text, "ASCII", "UTF-8", sub="byte")
    
    # Load the data as a corpus
    docs <- Corpus(VectorSource(or_text))
    
    # Text Transformation
    toSpace <- content_transformer(function (x , pattern ) gsub(pattern, " ", x))
    docs <- tm_map(docs, toSpace, "/")
    docs <- tm_map(docs, toSpace, "@")
    docs <- tm_map(docs, toSpace, "\\|")
    docs <- tm_map(docs, function(x) iconv(enc2utf8(x), sub = "byte"))
    
    # Cleaning text 
    
    # Convert the text to lower case
    docs <- tm_map(docs, content_transformer(tolower))
    # Remove numbers
    docs <- tm_map(docs, removeNumbers)
    # Remove english common stopwords
    docs <- tm_map(docs, removeWords, stopwords("english"))
    # Remove your own stop word
    # specify your stopwords as a character vector
    docs <- tm_map(docs, removeWords, c("")) 
    # Remove punctuations
    docs <- tm_map(docs, removePunctuation)
    # Eliminate extra white spaces
    docs <- tm_map(docs, stripWhitespace)
    # Text stemming
    # docs <- tm_map(docs, stemDocument)
    
    # term-document matrix
    docs_dtm <- TermDocumentMatrix(docs)
    docs_m <- as.matrix(docs_dtm)
    docs_v <- sort(rowSums(docs_m ),decreasing=TRUE)
    docs_df <- data.frame(word = names(docs_v),freq=docs_v)
    return(docs_df)
  }

  # Most frequent words 
  # based on Automated Authority Message Implementation Support (Reason)
  cs_alert <- tm_crime(cs_df[10])
  row.names(cs_alert) <- c()
  df_alert <- cs_alert[1:20,]
  df_alert$word <- as.character(df_alert$word)
  
  output$fig2 <- renderPlotly({
    df_alert %>% 
      plot_ly(x = ~word, y = ~freq, type = 'bar', color = I('orange')) %>% 
      layout(title = "Most Frequent Words",
             xaxis = list(title = ""),
             yaxis = list(title = ""))
  })
  
  # word cloud based on Alarm Siren Implementation support (Reason)
  cs_alarm <- tm_crime(cs_df[8])
  
  # word cloud plot
  output$alarm_cloud <- renderWordcloud2({
    wordcloud2(cs_alarm, color='random-dark')
  })
  
  # Feedback table 
  output$Feedback_table <- renderDataTable({
    DT::datatable(cs_df[, c(8,10)],
                  rownames = T,
                  filter = "top",
                  options = list(pageLength = 5, scrollX = TRUE, info = FALSE))
  })
  
  # Sentiment Analysis 
  
  # Alarm Question 
  # Create a character vector
  alarm_emo <- as.character(cs_df[8])
  # Get sentiment
  alarm_emo <- get_nrc_sentiment(alarm_emo)
  # Transform sentiment dataframe
  talarm_emo <- as.data.frame(t(alarm_emo))
  # Rename the rownames and score value column 
  talarm_emo <- rownames_to_column(talarm_emo, var = "Sentiment")
  names(talarm_emo)[2] <- "Score"
  
  # Alert Question 
  # Create a character vector
  alert_emo <- as.character(cs_df[10])
  # Get sentiment
  alert_emo <- get_nrc_sentiment(alert_emo)
  # Transform sentiment dataframe
  talert_emo <- as.data.frame(t(alert_emo))
  # Rename the rownames and score value column 
  talert_emo <- rownames_to_column(talert_emo, var = "Sentiment")
  names(talert_emo)[2] <- "Score"
  
  # Get emotion percentage of alarm question
  talarm_plot <- talarm_emo %>% 
    mutate(pct = Score/sum(Score), 
           lbl = scales::percent(pct))
  
  # Get emotion percentage of highlights 
  talert_plot <- talert_emo %>% 
    mutate(pct = Score/sum(Score), 
           lbl = scales::percent(pct))
  
  # Sentiment plot for Alarm siren long question response 
  output$fig3 <- renderPlotly({
    amplot <- talarm_plot %>% 
      ggplot(aes(x = reorder(Sentiment, -Score), y = Score)) +
      geom_bar(stat = "identity",
               fill = "#56B4E9") +
      geom_text(aes(label = lbl),
                vjust = -0.25) +
      labs(x = "", y = "",
           title = "Sentiments for Alarm Siren Implementation Support") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45))
    
    ggplotly(amplot)
  })
  
  # Sentiment plot for Automated Alert long question response 
  output$fig4 <- renderPlotly({
    atplot <- talert_plot %>% 
      ggplot(aes(x = reorder(Sentiment, -Score), y = Score)) +
      geom_bar(stat = "identity",
               fill = "#56B4E9") +
      geom_text(aes(label = lbl),
                vjust = -0.25) +
      labs(x = "", y = "",
           title = "Sentiments for Automated Authority Message Implementation Support") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45))
    
    ggplotly(atplot)
  })
  
})