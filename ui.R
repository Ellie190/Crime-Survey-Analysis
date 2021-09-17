#source("utils/loadpackages.R")
library(shinydashboard)
library(shiny)
library(stringr)
library(tidyverse)
library(scales)
library(ggplot2)
library(plotly)
library(knitr)
library(DT)
library(rpivotTable)
library(openintro)
library(tidyr)
library(tm)
library(SnowballC)
library(wordcloud2)
library(RColorBrewer)
library(RCurl)
library(XML)
library(rlang)
library(syuzhet)
library(janitor)
library(shinycssloaders)
library(auth0)

# background image 
bgImg <- tags$img(src = "background.jpg",
                  style = "position: absolute;
                           height:100%;width:100%")

# Dashboard 
auth0_ui(
  dashboardPage(skin = "yellow", title = "Survey Analysis",
                dashboardHeader(title = "Crime Surveillance System Survey Analysis",
                                titleWidth = 420), # end of header
                dashboardSidebar(disable = TRUE), # end of sidebar
                dashboardBody(
                  bgImg,
                  fluidRow(
                    box(title = "Participant Response", solidHeader = TRUE, width = 8,
                        collapsible = TRUE, status = "primary",
                        withSpinner(plotlyOutput("fig1"))),
                    box(title = "Survey Question/Option", solidHeader = TRUE, width = 4,
                        collapsible = TRUE, status = "primary",
                        uiOutput("ques"), h3("Info"),
                        "Under the Participant Feedback tab where written 'All', click and search the most 
          frequent words and large words that appear on the Automated Authority Message 
          Implementation support (Reason) tab and Alarm Siren Implementation support (Reason) tab 
          respectively to get a better sense of the sentence the words come from.")
                  ),
                  fluidRow(
                    tabBox(width = 12,
                           tabPanel(h4("Automated Authority Message Feedback"), 
                                    withSpinner(plotlyOutput("fig2"))),
                           tabPanel(h4("Alarm Siren Feedback"),
                                    wordcloud2Output("alarm_cloud",height = 400, width = "auto")),
                           tabPanel(h4("Participant Feedback"),
                                    withSpinner(dataTableOutput("Feedback_table", width = "auto"))),
                           tabPanel(h4("Alarm Sentiments"),
                                    withSpinner(plotlyOutput("fig3"))),
                           tabPanel(h4("Alert Sentiments"),
                                    withSpinner(plotlyOutput("fig4"))),
                           tabPanel(h4("Logout"), logoutButton()))
                  )
                ) # end of body 
  ) # end of Page 
)