rm(list=ls())
library(ggplot2)

d <- read.csv("../data/ud_preds.csv")

p <- ggplot(d, aes(x = distance, y = mean)) +
  geom_line(linewidth = 1, color = "#0072B2") +
  geom_pointrange(
    aes(ymin = ci_lower, ymax = ci_upper),
    color = "#0072B2",
    size = 1,
    fatten = 4
  ) +
  scale_x_continuous(breaks = d$distance) +
  scale_y_continuous(limits = c(0, NA)) +
  labs(
    x = "Distance",
    y = "Predictive Potential (bits)"
  ) +
  theme_bw() +
  theme(
    axis.text = element_text(size = 10),
    axis.title.x = element_text(size = 16),
    axis.title.y = element_text(size = 16),
    legend.position = "none",
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank()
  )

p

ggsave("../result/png/ud_preds.png", device = "png", width = 6, height = 4, units = "in", dpi = 600, bg = "transparent")
ggsave("../result/pdf/ud_preds.pdf", device = "pdf", width = 6, height = 4, units = "in", bg = "transparent")
