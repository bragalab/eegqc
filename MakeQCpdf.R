# Organize all QC figures on one pdf document. Delete all temporary figures/files
#Last step of QCpdf pipeline.
#
#
library.path <- .libPaths()

OUTPATH <- toString(commandArgs(trailingOnly=TRUE))
# load libraries
  setwd('~')
  if(!require(grDevices)){install.packages(c("grDevices")); require(grDevices)}
  if(!require("qpdf")) {install.packages(c("qpdf")); require("qpdf")}
  if (!require(plyr)) {install.packages(c("plyr")); require(plyr)}
  if (!require(lmPerm)) {install.packages(c("lmPerm")); require(lmPerm)}    
  if (!require("coin")) {install.packages(c("coin")); require("coin")}  
  if (!require("ggplot2")) {install.packages(c("ggplot2")); require("ggplot2")}  
  if (!require("gridExtra")) {install.packages(c("gridExtra")); require("gridExtra")}   
  if (!require("plotrix")) {install.packages(c("plotrix")); require("plotrix")}  
  if (!require("knitr")) {install.packages(c("knitr")); require("knitr")}  
  if (!require("xtable")) {install.packages(c("xtable")); require("xtable")}  
  if (!require("pander")) {install.packages(c("pander")); require("pander")}  
  if (!require("stargazer")) {install.packages(c("stargazer")); require("stargazer")}  
  if (!require("rhandsontable")) {install.packages(c("rhandsontable")); require("rhandsontable")}  
  if (!require("gtable")) {install.packages(c("gtable")); require("gtable")}  
  if (!require("grid")) {install.packages(c("grid")); require("grid")}  
  if (!require("RGraphics")) {install.packages(c("RGraphics")); require("RGraphics")}  
  if (!require("cowplot")) {install.packages(c("cowplot")); require("cowplot")}  
  if (!require("png")) {install.packages(c("png")); require("png")}

#load table info

  setwd(OUTPATH)
  fileinfo <- unlist(strsplit(OUTPATH, '/'))
  header <- read.csv(paste(OUTPATH, '/header.csv', sep =''))
  SubjectID <- header$SubjectID
  headertext1 <- textGrob("iEEG QC REPORT", x = 0.0, just ='left', 
                              gp=gpar(fontsize=14, fontface='bold'))
  headertext2 <- textGrob(paste(paste("Subject ID: ", header$SubjectID,sep = "") ,
                                paste("Session: ", header$Session, sep = ""),
                                paste("Task: ", header$Task, sep = ""), sep = "     "), 
                                 x = 0.0, just ='left', gp=gpar(fontsize=14))
  tt2 <- ttheme_minimal(base_size = 9)
  if (grepl('STIM',OUTPATH, ignore.case = FALSE, perl = FALSE, fixed = FALSE, useBytes = FALSE)){
    headertable <- tableGrob(header[1,4:8], row = NULL, theme = tt2)
  } else {
    headertable <- tableGrob(header[1,4:7], row = NULL, theme = tt2)
  }

  headertable <- gtable_add_grob(headertable, grobs=rectGrob(gp=gpar(fill=NA, lwd = 1)),
                                 t = 2, b = nrow(headertable), l = 1, r = ncol(headertable))
#load graphs

  statsimg <- rasterGrob(readPNG('statsplot.png'))
  powerspectrumimg <- rasterGrob(readPNG('powerspectrum.png'))
  carpetplotimg_blank <- rasterGrob(readPNG('carpetplot_blank.png'))
  carpetplotimg_good <- rasterGrob(readPNG('carpetplot_good.png'))
  carpetplotimg_stim <- rasterGrob(readPNG('carpetplot_stim.png'))
  colorbarimg <- rasterGrob(readPNG('colorbar.png'))
  raw1img <- rasterGrob(readPNG('raw1.png'))
  raw2img <- rasterGrob(readPNG('raw2.png'))
  raw3img <- rasterGrob(readPNG('raw3.png'))
  raw4img <- rasterGrob(readPNG('raw4.png'))

  blank <- grid.rect(gp=gpar(fill="white", lwd = 0, col = "white"))
  
#place on PDF  
  invisible(pdf('tmp1.pdf', height = 11, width = 8.5, onefile = T))
  
  QC1 <- grid.arrange(arrangeGrob(blank, ncol = 1),
                      arrangeGrob(blank, headertext1, headertext2, ncol = 3, widths = c(0.5, 2, 6)), 
                      arrangeGrob(blank, headertable, ncol = 2, widths = c(0.25, 8.25)),
                      arrangeGrob(carpetplotimg_stim, ncol = 1),
                      arrangeGrob(carpetplotimg_good, ncol=1),
                      arrangeGrob(carpetplotimg_blank, ncol=1),
                      arrangeGrob(colorbarimg, ncol=1),
                      arrangeGrob(blank, ncol = 1),
                           nrow = 8, ncol = 1, heights = c(0.5, 0.5, 0.75, 1, 6, 2, 0.5, 0.25))
  invisible(dev.off())
  
  invisible(pdf('tmp2.pdf', height = 11, width = 8.5, onefile = T))
  
  QC2 <- grid.arrange(arrangeGrob(blank, ncol = 1),
                      arrangeGrob(statsimg, ncol = 1),
                      arrangeGrob(powerspectrumimg, ncol = 1),
                      arrangeGrob(blank, ncol = 1),
                      nrow = 4, ncol = 1, heights = c(0.5, 7, 3.5, 0.5))
  invisible(dev.off())  
  
  invisible(pdf('tmp4.pdf', height = 11, width = 8.5, onefile = T))
  QC4 <- grid.arrange(arrangeGrob(blank, ncol = 1),
			arrangeGrob(raw1img),
			arrangeGrob(blank, ncol = 1),
			nrow = 3, ncol = 1, heights = c(0.25, 10.5, 0.25))
  invisible(dev.off())

  invisible(pdf('tmp5.pdf', height = 11, width = 8.5, onefile = T))
  QC5 <- grid.arrange(arrangeGrob(blank, ncol = 1),
			arrangeGrob(raw2img),
			arrangeGrob(blank, ncol = 1),
			nrow = 3, ncol = 1, heights = c(0.25, 10.5, 0.25))
  invisible(dev.off())

  invisible(pdf('tmp6.pdf', height = 11, width = 8.5, onefile = T))
  QC6 <- grid.arrange(arrangeGrob(blank, ncol = 1),
			arrangeGrob(raw3img),
			arrangeGrob(blank, ncol = 1),
			nrow = 3, ncol = 1, heights = c(0.25, 10.5, 0.25))
  invisible(dev.off())

  invisible(pdf('tmp7.pdf', height = 11, width = 8.5, onefile = T))
  QC7 <- grid.arrange(arrangeGrob(blank, ncol = 1),
			arrangeGrob(raw4img),
			arrangeGrob(blank, ncol = 1),
			nrow = 3, ncol = 1, heights = c(0.25, 10.5, 0.25))
  invisible(dev.off())

  #determine final file name
  FILEINFO <- unlist(strsplit(OUTPATH,'/'))
  last <- length(FILEINFO)
  
  if (grepl('STIM',OUTPATH, ignore.case = FALSE, perl = FALSE, fixed = FALSE, useBytes = FALSE)){
      FILENAME <- paste( OUTPATH, paste( FILEINFO[last-4], FILEINFO[last-3], FILEINFO[last-2], FILEINFO[last-1], FILEINFO[last], 'QC.pdf', sep = '_'), sep = '/')
  } else{
      FILENAME <- paste( OUTPATH, paste( FILEINFO[last-2], FILEINFO[last-1], FILEINFO[last], 'QC.pdf', sep = '_'), sep = '/')
  }
  
  #combine temporary pdf files, but only ones that aren't blank
  filelist <- list()
  file_counter <- 1
  for(i in list.files(pattern = '^tmp')){
    print(i)
    if (file.info(i)$size > 18000){
      invisible(filelist[[file_counter]] <- i)
      file_counter <- file_counter + 1
    }
  }  
  pdf_combine(filelist,
              FILENAME, password = "")
  
  #delete all temporary files and images
  invisible(file.remove('tmp1.pdf'))
  invisible(file.remove('tmp2.pdf'))
  invisible(file.remove('tmp4.pdf'))
  invisible(file.remove('tmp5.pdf'))
  invisible(file.remove('tmp6.pdf'))
  invisible(file.remove('tmp7.pdf'))
  invisible(file.remove('Rplots.pdf'))
  invisible(file.remove('carpetplot_blank.png'))
  invisible(file.remove('carpetplot_good.png'))
  invisible(file.remove('carpetplot_stim.png'))
  invisible(file.remove('colorbar.png'))
  invisible(file.remove('header.csv'))
  invisible(file.remove('powerspectrum.png'))
  invisible(file.remove('raw1.png'))
  invisible(file.remove('raw2.png'))
  invisible(file.remove('raw3.png'))
  invisible(file.remove('raw4.png'))
  invisible(file.remove('statsplot.png'))
	if (length(grep("[[:digit:]]", SubjectID)) == 0 && header$Session != 'NWB'){ #for NU Research data
	  invisible(file.remove('downsampled_data_uV.mat'))
	}
