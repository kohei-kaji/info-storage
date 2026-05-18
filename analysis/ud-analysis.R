rm(list=ls())
library(readr)
library(dplyr)
library(tidyr)
library(plotrix)
library(ggplot2)



dltpath <- "../data/gum_dlt.csv"
storpath <- "../data/gum_bert_sum.csv"
df1 <- read_csv(dltpath, col_types = cols_only(sentid="c",wordid="d",dlt_stor="d"))
df2 <- read_csv(storpath, col_types = cols_only(sentid="c",wordid="d",bert_stor="d"))
stopifnot(nrow(df1) == nrow(df2))
df <- df1 %>%  merge(df2, by = c("sentid","wordid"), sort = F)
r_pearson <- cor(df$dlt_stor, df$bert_stor, use = "complete.obs", method = "pearson")
r_spearman <- cor(df$dlt_stor, df$bert_stor, use = "complete.obs", method = "spearman")
label_text <- sprintf("atop(italic(r) == '%.3f', rho == '%.3f')", r_pearson, r_spearman)

cutoff_n <- 100
df_summary <- df %>%
  group_by(dlt_stor) %>%
  summarise(
    mean_y = mean(bert_stor, na.rm = TRUE),
    n = n(),
    se = std.error(bert_stor, na.rm = TRUE)
  ) %>%
  mutate(
    ci_lower = mean_y - 1.96 * se,
    ci_upper = mean_y + 1.96 * se
  ) %>%
  filter(n >= cutoff_n)
valid_dlt <- df_summary$dlt_stor
ggplot() +
  geom_smooth(data = df %>% filter(dlt_stor %in% valid_dlt), aes(x = dlt_stor, y = bert_stor), 
              method = "lm", formula = y ~ x, se = FALSE, 
              color = "red", linetype = "dashed") +
  geom_point(data = df_summary, aes(x = dlt_stor, y = mean_y), size = 3, color = "#0072B2") +
  geom_errorbar(data = df_summary, aes(x = dlt_stor, ymin = ci_lower, ymax = ci_upper), width = 0.2, color = "#0072B2") +
  annotate("text", x = -Inf, y = Inf, label = label_text, parse = TRUE, hjust = -0.1, vjust = 1.2, size = 5) +
  scale_x_continuous(breaks = seq(min(valid_dlt), max(valid_dlt), by = 1)) +
  labs(
    x = "DLT Storage Cost",
    y = "Mean Information Storage (bits)"
  ) +
  theme_bw() +
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank()
  )
ggsave("../result/png/info_dlt.png", device = "png", width = 4, height = 3, units = "in", dpi = 600, bg = "transparent")
ggsave("../result/pdf/info_dlt.pdf", device = "pdf", width = 4, height = 3, units = "in", bg = "transparent")



ggplot() +
  geom_smooth(data = df %>% filter(dlt_stor %in% valid_dlt), aes(x = dlt_stor, y = bert_stor), 
              method = "gam", formula = y ~ s(x, k = 4), se = TRUE,
              color = "red", linetype = "dashed") +
  geom_point(data = df_summary, aes(x = dlt_stor, y = mean_y),
             size = 3, color = "#0072B2") +
  geom_errorbar(data = df_summary, aes(x = dlt_stor, ymin = ci_lower, ymax = ci_upper),
                width = 0.2, color = "#0072B2") +
  annotate("text", x = -Inf, y = Inf, 
           label = label_text, parse = TRUE,
           hjust = -0.1, vjust = 1.2, size = 5) +
  scale_x_continuous(breaks = seq(min(valid_dlt), max(valid_dlt), by = 1)) +
  labs(
    x = "DLT Storage Cost",
    y = "Mean Information Storage (bits)"
  ) +
  theme_bw() +
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank()
  )
ggsave("../result/png/info_dlt_gam4.png", device = "png", width = 4, height = 3, units = "in", dpi = 600, bg = "transparent")




storpath <- "../data/gum_bertlarge_sum.csv"
df1 <- read_csv(dltpath, col_types = cols_only(sentid="c",wordid="d",dlt_stor="d"))
df2 <- read_csv(storpath, col_types = cols_only(sentid="c",wordid="d",bert_stor="d"))
stopifnot(nrow(df1) == nrow(df2))
df <- df1 %>%  merge(df2, by = c("sentid","wordid"), sort = F)
r_pearson <- cor(df$dlt_stor, df$bert_stor, use = "complete.obs", method = "pearson")
r_spearman <- cor(df$dlt_stor, df$bert_stor, use = "complete.obs", method = "spearman")
label_text <- sprintf("atop(italic(r) == '%.3f', rho == '%.3f')", r_pearson, r_spearman)

cutoff_n <- 100
df_summary <- df %>%
  group_by(dlt_stor) %>%
  summarise(
    mean_y = mean(bert_stor, na.rm = TRUE),
    n = n(),
    se = std.error(bert_stor, na.rm = TRUE)
  ) %>%
  mutate(
    ci_lower = mean_y - 1.96 * se,
    ci_upper = mean_y + 1.96 * se
  ) %>%
  filter(n >= cutoff_n)
valid_dlt <- df_summary$dlt_stor
ggplot() +
  geom_smooth(data = df %>% filter(dlt_stor %in% valid_dlt), aes(x = dlt_stor, y = bert_stor), method = "lm", formula = y ~ x, se = FALSE, color = "red", linetype = "dashed") +
  geom_point(data = df_summary, aes(x = dlt_stor, y = mean_y), size = 3, color = "#E69F00") +
  geom_errorbar(data = df_summary, aes(x = dlt_stor, ymin = ci_lower, ymax = ci_upper), width = 0.2, color = "#E69F00") +
  annotate("text", x = -Inf, y = Inf, 
           label = label_text, parse = TRUE,
           hjust = -0.1, vjust = 1.2, size = 5) +
  scale_x_continuous(breaks = seq(min(valid_dlt), max(valid_dlt), by = 1)) +
  labs(
    x = "DLT Storage Cost",
    y = "Mean Information Storage (bits)",
    color = NULL
  ) +
  theme_bw() +
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank()
  )
ggsave("../result/png/info_dlt_bertlarge.png", device = "png", width = 4, height = 3, units = "in", dpi = 600, bg = "transparent")
ggsave("../result/pdf/info_dlt_bertlarge.pdf", device = "pdf", width = 4, height = 3, units = "in", bg = "transparent")





storpath <- "../data/gum_roberta_sum.csv"
df1 <- read_csv(dltpath, col_types = cols_only(sentid="c",wordid="d",dlt_stor="d"))
df2 <- read_csv(storpath, col_types = cols_only(sentid="c",wordid="d",roberta_stor="d"))
stopifnot(nrow(df1) == nrow(df2))
df <- df1 %>%  merge(df2, by = c("sentid","wordid"), sort = F)
r_pearson <- cor(df$dlt_stor, df$roberta_stor, use = "complete.obs", method = "pearson")
r_spearman <- cor(df$dlt_stor, df$roberta_stor, use = "complete.obs", method = "spearman")
label_text <- sprintf("atop(italic(r) == '%.3f', rho == '%.3f')", r_pearson, r_spearman)

cutoff_n <- 100
df_summary <- df %>%
  group_by(dlt_stor) %>%
  summarise(
    mean_y = mean(roberta_stor, na.rm = TRUE),
    n = n(),
    se = std.error(roberta_stor, na.rm = TRUE)
  ) %>%
  mutate(
    ci_lower = mean_y - 1.96 * se,
    ci_upper = mean_y + 1.96 * se
  ) %>%
  filter(n >= cutoff_n)
valid_dlt <- df_summary$dlt_stor
ggplot() +
  geom_smooth(data = df %>% filter(dlt_stor %in% valid_dlt), aes(x = dlt_stor, y = roberta_stor), method = "lm", formula = y ~ x, se = FALSE, color = "red", linetype = "dashed") +
  geom_point(data = df_summary, aes(x = dlt_stor, y = mean_y), size = 3, color = "#009E73") +
  geom_errorbar(data = df_summary, aes(x = dlt_stor, ymin = ci_lower, ymax = ci_upper), width = 0.2, color = "#009E73", show.legend = FALSE) +
  annotate("text", x = -Inf, y = Inf, 
           label = label_text, parse = TRUE,
           hjust = -0.1, vjust = 1.2, size = 5) +
  scale_x_continuous(breaks = seq(min(valid_dlt), max(valid_dlt), by = 1)) +
  labs(
    x = "DLT Storage Cost",
    y = "Mean Information Storage (bits)",
    color = NULL
  ) +
  theme_bw() +
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank()
  )
ggsave("../result/png/info_dlt_roberta.png", device = "png", width = 4, height = 3, units = "in", dpi = 600, bg = "transparent")
ggsave("../result/pdf/info_dlt_roberta.pdf", device = "pdf", width = 4, height = 3, units = "in", bg = "transparent")
