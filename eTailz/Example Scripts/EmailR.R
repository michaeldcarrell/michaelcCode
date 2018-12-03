Sys.setenv(JAVA_HOME='C:/Program Files/Java/jre1.8.0_161')
library(rJava)
library(mailR)

from<-"MichaelC@etailz.com"
to<-"mikace2010@gmail.com"
subject<-"Totes a Subject"


send.mail(from = "MichaelC@etailz.com",
          to = "mikace2010@gmail.com",
          subject = subject,
          body = "msg", 
          authenticate = TRUE,
          smtp = list(host.name = "smtp.office365.com", port = 587,
                      user.name = from, passwd = "ASDFtyu092018", tls = TRUE),
          attach.files = "FilePath")
