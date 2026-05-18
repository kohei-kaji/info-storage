rm(list=ls())
library(tidyverse)
library(ggplot2)

d <- read_csv("../data/center_embedding_bert.csv")

df_summary <- d %>%
  filter(!is.na(stor)) %>%
  group_by(condition, word_position, region) %>%
  summarise(
    mean_stor = mean(stor, na.rm = TRUE),
    sd_stor = sd(stor, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  ) %>%
  mutate(
    se = sd_stor / sqrt(n),
    ci_lower = mean_stor - 1.96 * se,
    ci_upper = mean_stor + 1.96 * se,
    condition_label = factor(
      condition,
      levels = c("CE", "RB"), 
      labels = c("Center Embedding", "Right Branching")
    )
  )

axis_labels <- df_summary %>%
  select(word_position, region, condition) %>%
  mutate(
    y_pos = if_else(condition == "CE", -4, -6.7),
    condition_label = if_else(condition == "CE", "Center Embedding", "Right Branching")
  )

ggplot(df_summary, aes(x = word_position, y = mean_stor, color = condition_label, shape = condition_label)) +
  geom_errorbar(aes(ymin = ci_lower, ymax = ci_upper), width = 0.2, alpha = 0.7, show.legend = FALSE) +
  geom_line(linewidth = 0.7, alpha = 0.7, show.legend = FALSE) +
  geom_point(size = 4) +
  geom_text(
    data = axis_labels,
    aes(x = word_position, y = y_pos, label = region, color = condition_label),
    size = 3.2,
    fontface = "bold",
    inherit.aes = FALSE, 
    show.legend = FALSE
  ) +
  scale_color_manual(values = c("Center Embedding" = "#0072B2", "Right Branching" = "#D55E00")) +
  scale_x_continuous(breaks = 1:max(df_summary$word_position)) +
  coord_cartesian(ylim = c(0, 50), clip = "off") +
  
  labs(
    x = NULL,
    y = "Information Storage (bits)",
    color = NULL,
    shape = NULL
  ) +
  theme_bw() +
  theme(
    legend.position = c(0.82, 0.88), 
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank(),
    axis.text.y = element_text(size = 11),
    axis.title = element_text(size = 12),
    plot.margin = margin(t = 10, r = 10, b = 25, l = 10)
  )
ggsave("../result/png/centerembedding_bert.png", device = "png", width = 5, height = 3.5, units = "in", dpi = 600, bg = "transparent")
ggsave("../result/pdf/centerembedding_bert.pdf", device = "pdf", width = 5, height = 3.5, units = "in", bg = "transparent")



df_total_stats <- d %>%
  group_by(item, condition) %>%
  summarise(total_sentence_stor = sum(stor), .groups = "drop") %>%
  group_by(condition) %>%
  summarise(
    mean_total_stor = mean(total_sentence_stor),
    sd_total_stor = sd(total_sentence_stor),
    n = n()
  ) %>%
  mutate(
    mean_formatted = sprintf("%.2f", mean_total_stor),
    sd_formatted = sprintf("%.2f", sd_total_stor),
    condition_label = factor(
      condition,
      levels = c("CE", "RB"),
      labels = c("Center Embedding", "Right Branching")
    )
  )

df_total_stats %>% 
  transmute(Condition = condition_label, 
            `Mean Total Storage (bits)` = mean_formatted,
            `SD` = sd_formatted) %>% 
  print()



d_rel <- read_csv("../data/relative_clause_bert.csv")

df_summary <- d_rel %>%
  filter(!is.na(stor)) %>%
  group_by(condition, word_position, region) %>%
  summarise(
    mean_stor = mean(stor, na.rm = TRUE),
    sd_stor = sd(stor, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  ) %>%
  mutate(
    se = sd_stor / sqrt(n),
    ci_lower = mean_stor - 1.96 * se,
    ci_upper = mean_stor + 1.96 * se,
    condition_label = factor(
      condition,
      levels = c("SR", "OR"),
      labels = c("Subject Relative", "Object Relative")
    )
  )

axis_labels <- df_summary %>%
  select(word_position, region, condition) %>%
  mutate(
    y_pos = if_else(condition == "SR", -3, -5),
    condition_label = if_else(condition == "SR", "Subject Relative", "Object Relative")
  )


ggplot(df_summary, aes(x = word_position, y = mean_stor, color = condition_label, shape = condition_label)) +
  geom_errorbar(aes(ymin = ci_lower, ymax = ci_upper), width = 0.2, alpha = 0.7, show.legend = FALSE) +
  geom_line(linewidth = 0.7, alpha = 0.7, show.legend = FALSE) +
  geom_point(size = 4) +
  geom_text(
    data = axis_labels,
    aes(x = word_position, y = y_pos, label = region, color = condition_label),
    size = 3.2,
    fontface = "bold",
    inherit.aes = FALSE, 
    show.legend = FALSE
  ) +
  scale_color_manual(values = c("Subject Relative" = "#0072B2", "Object Relative" = "#D55E00")) +
  scale_x_continuous(breaks = 1:max(df_summary$word_position)) +
  coord_cartesian(ylim = c(0, 36), clip = "off") +
  
  labs(
    x = NULL,
    y = "Information Storage (bits)",
    color = NULL,
    shape = NULL
  ) +
  theme_bw() +
  theme(
    legend.position = c(0.82, 0.88), 
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank(),
    axis.text.y = element_text(size = 11),
    axis.title = element_text(size = 12),
    plot.margin = margin(t = 10, r = 10, b = 25, l = 10)
  )


ggsave("../result/png/relatives_bert.png", device = "png", width = 5, height = 3.5, units = "in", dpi = 600, bg = "transparent")
ggsave("../result/pdf/relatives_bert.pdf", device = "pdf", width = 5, height = 3.5, units = "in", bg = "transparent")

df_total_stats_rel <- d_rel %>%
  filter(!is.na(stor)) %>%
  group_by(item, condition) %>%
  summarise(total_sentence_stor = sum(stor), .groups = "drop") %>%
  group_by(condition) %>%
  summarise(
    mean_total_stor = mean(total_sentence_stor),
    sd_total_stor = sd(total_sentence_stor),
    n = n()
  ) %>%
  mutate(
    mean_formatted = sprintf("%.2f", mean_total_stor),
    sd_formatted = sprintf("%.2f", sd_total_stor),
    condition_label = factor(
      condition,
      levels = c("SR", "OR"),
      labels = c("Subject Relative", "Object Relative")
    )
  )

df_total_stats_rel %>% 
  transmute(Condition = condition_label, 
            `Mean Total Storage (bits)` = mean_formatted,
            `SD` = sd_formatted) %>% 
  print()





