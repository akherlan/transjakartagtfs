library(diagram)

pos <- coordinates(c(4, 4, 4))
# plot(pos, type = "n")
# text(pos)

lab <- c("Start", NA, NA, NA,
         "Collect\ntransit data",
         "Transform\ndata",
         "Validation",
         "Done",
         NA, " Completion ", NA, NA)

edgelength <- 0.09
textsize <- 1.2   # 0.6
boxcol <- "grey95"
shadowcol <- "lightblue"

png("figs/flow.png", width = 750, height = 380)

openplotmat()
straightarrow(from = pos[1,], to = pos[5,])
straightarrow(from = pos[5,], to = pos[6,])
straightarrow(from = pos[6,], to = pos[7,])
straightarrow(from = pos[7,], to = pos[8,])
segmentarrow(from = pos[7,], to = pos[10,], dd = 0)
segmentarrow(from = pos[10,], to = pos[5,], dd = 0.25)
straightarrow(from = pos[10,], to = pos[6,])

for (i in c(1, 5:8, 10)) {
  if(i == 7) {
    textdiamond(
      mid = pos[i,],
      radx = 0.11,
      rady = 0.11,
      lab = lab[i],
      cex = textsize,
      box.col = boxcol,
      shadow.col = shadowcol)
  } else if (i %in% c(1, 8)) {
    textellipse(
      mid = pos[i,],
      radx = edgelength,
      rady = edgelength,
      lab = lab[i],
      cex = textsize,
      box.col = boxcol,
      shadow.col = shadowcol)
  } else if (i == 10) {
    textempty(
      mid = pos[i,],
      lab = lab[i],
      cex = textsize,
      box.col = "white")
  } else {
    textrect(
      mid = pos[i,],
      radx = edgelength,
      rady = edgelength,
      lab = lab[i],
      cex = textsize,
      box.col = boxcol,
      shadow.col = shadowcol)
  }
}

dev.off()
