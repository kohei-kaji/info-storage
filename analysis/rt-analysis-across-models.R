rm(list=ls())
library(readr)
library(dplyr)
library(tidyr)
library(corrplot)
library(plotrix)
library(jmuOutlier)
library(ggplot2)


pred_path <- "../data/naturalstories/preds.csv"
pred <- read_csv(pred_path,col_types = cols_only(wlen="d",unisurp="d",surp="d",zone="d",position="d",story="c")) %>% mutate(zone_id = zone)
positions <- read_csv(pred_path,col_types = cols_only(zone="d",is_punct="d",bos="d",eos="d",story="c")) %>% rename(zone_id = zone)

storinfo_path <- "../data/ns_bert_stor_sum.csv"
storinfo <- read_csv(storinfo_path,col_types = cols_only(stor="d")) %>% rename(bertstor = stor)
pred <- bind_cols(pred, storinfo)
storinfo_path <- "../data/ns_bertlarge_stor_sum.csv"
storinfo <- read_csv(storinfo_path,col_types = cols_only(stor="d")) %>% rename(bertlargestor = stor)
pred <- bind_cols(pred, storinfo)
storinfo_path <- "../data/ns_roberta_stor_sum.csv"
storinfo <- read_csv(storinfo_path,col_types = cols_only(stor="d")) %>% rename(robertastor = stor)
pred <- bind_cols(pred, storinfo)


dltstor_path <- "../data/ns_dlt.csv"
dltstor <- read_csv(dltstor_path,col_types = cols_only(dlt_stor="d"))
stopifnot(nrow(pred) == nrow(dltstor))
pred <- bind_cols(pred, dltstor)


pred_so1 <- pred %>% 
  mutate(zone_id = zone_id + 1) %>% 
  select(-zone) %>%
  rename_with(~ paste(., "_so1", sep = "")) %>%
  rename(story = story_so1, zone_id = zone_id_so1)
pred <- pred %>%
  merge(pred_so1, by = c("story", "zone_id"), sort = F) %>%
  merge(positions, by = c("story", "zone_id"), sort = F) %>%
  filter(is_punct==0, bos==0, eos==0) %>%
  select(-is_punct, -bos, -eos)


pred <- pred %>%
  mutate_at(
    vars(
        zone,position,
        wlen,unisurp,surp,
        wlen_so1,unisurp_so1,surp_so1,
        dlt_stor,dlt_stor_so1,
        bertstor,bertstor_so1,
        bertlargestor,bertlargestor_so1,
        robertastor,robertastor_so1,
    ),
    function(x) {scale(x, center=T, scale=T)})

rt_path <- "../data/naturalstories/naturalstories_RTS/processed_RTs.tsv"
rts_summary <- read.table(rt_path, sep = "\t", quote = "", header = TRUE) %>% 
  select(WorkerId, item, zone, RT) %>%
  rename(story = item, zone_id = zone) %>%
  group_by(story, zone_id) %>%
  summarise(mean_RT = mean(RT, na.rm = TRUE), .groups = "drop")
df_ns <- merge(rts_summary, pred, by = c("story","zone_id"), sort=F)


maze <- read_rds("../data/maze/maze.rds") %>%
  group_by(story, zone) %>%
  summarise(mean_RT = mean(maze_RT, na.rm = TRUE), .groups = "drop") %>% rename(zone_id=zone)
df_ns_maze <- merge(maze, pred, by = c("story","zone_id"), sort=F)




pred_path <- "../data/OneStop/preds.csv"
pred <- read_csv(pred_path,col_types = cols_only(wlen="d",unisurp="d",surp="d",zone="d",position="d",article_batch="c",article_id="c",difficulty_level="c")) %>%
    mutate(zone_id = zone, story = paste(article_batch, article_id, difficulty_level, sep="-"))
positions <- read_csv(pred_path,col_types = cols_only(zone="d",is_punct="d",bos="d",eos="d",article_batch="c",article_id="c",difficulty_level="c")) %>%
    mutate(story = paste(article_batch, article_id, difficulty_level, sep="-")) %>%
    rename(zone_id = zone)

storinfo_path <- "../data/os_bert_stor_sum.csv"
storinfo <- read_csv(storinfo_path,col_types = cols_only(stor="d")) %>% rename(bertstor = stor)
pred <- bind_cols(pred, storinfo)
storinfo_path <- "../data/os_bertlarge_stor_sum.csv"
storinfo <- read_csv(storinfo_path,col_types = cols_only(stor="d")) %>% rename(bertlargestor = stor)
pred <- bind_cols(pred, storinfo)
storinfo_path <- "../data/os_roberta_stor_sum.csv"
storinfo <- read_csv(storinfo_path,col_types = cols_only(stor="d")) %>% rename(robertastor = stor)
pred <- bind_cols(pred, storinfo)


dltstor_path <- "../data/os_dlt.csv"
dltstor <- read_csv(dltstor_path,col_types = cols_only(dlt_stor="d"))
stopifnot(nrow(pred) == nrow(dltstor))
pred <- bind_cols(pred, dltstor)


pred_so1 <- pred %>% 
  mutate(zone_id = zone_id + 1) %>% 
  select(-zone) %>%
  rename_with(~ paste(., "_so1", sep = "")) %>%
  rename(story = story_so1, zone_id = zone_id_so1)
pred <- pred %>%
  merge(pred_so1, by = c("story", "zone_id"), sort = F) %>%
  merge(positions, by = c("story", "zone_id"), sort = F) %>%
  filter(is_punct==0, bos==0, eos==0) %>%
  select(-is_punct, -bos, -eos)



pred <- pred %>%
  mutate_at(
    vars(
      zone,position,
      wlen,unisurp,surp,
      wlen_so1,unisurp_so1,surp_so1,
      dlt_stor,dlt_stor_so1,
      bertstor,bertstor_so1,
      bertlargestor,bertlargestor_so1,
      robertastor,robertastor_so1
    ),
    function(x) {scale(x, center=T, scale=T)})

rt_path <- "../data/OneStop/rts.csv"
rts_summary <- read_csv(rt_path, col_types = cols_only(article_batch="c",article_id="c",difficulty_level="c",zone="d",IA_FIRST_RUN_DWELL_TIME= "d"), na = c("", "NA", ".")) %>%
  mutate(story = paste(article_batch, article_id, difficulty_level, sep="-")) %>%
  rename(zone_id = zone) %>%
  mutate(IA_FIRST_RUN_DWELL_TIME = replace_na(IA_FIRST_RUN_DWELL_TIME, 0)) %>%
  group_by(story, zone_id) %>%
  summarise(mean_RT = mean(IA_FIRST_RUN_DWELL_TIME, na.rm = TRUE), .groups = "drop")
df_osfp <- merge(rts_summary, pred, by = c("story","zone_id"), sort=F)

rts_summary <- read_csv(rt_path, col_types = cols_only(article_batch="c",article_id="c",difficulty_level="c",zone="d",IA_REGRESSION_PATH_DURATION= "d"), na = c("", "NA", ".")) %>%
  mutate(story = paste(article_batch, article_id, difficulty_level, sep="-")) %>%
  rename(zone_id = zone) %>%
  mutate(IA_REGRESSION_PATH_DURATION = replace_na(IA_REGRESSION_PATH_DURATION, 0)) %>%
  group_by(story, zone_id) %>%
  summarise(mean_RT = mean(IA_REGRESSION_PATH_DURATION, na.rm = TRUE), .groups = "drop")
df_osgp <- merge(rts_summary, pred, by = c("story","zone_id"), sort=F)


rts_summary <- read_csv(rt_path, col_types = cols_only(article_batch="c",article_id="c",difficulty_level="c",zone="d",IA_DWELL_TIME= "d"), na = c("", "NA", ".")) %>%
  mutate(story = paste(article_batch, article_id, difficulty_level, sep="-")) %>%
  rename(zone_id = zone) %>%
  mutate(IA_DWELL_TIME = replace_na(IA_DWELL_TIME, 0)) %>%
  group_by(story, zone_id) %>%
  summarise(mean_RT = mean(IA_DWELL_TIME, na.rm = TRUE), .groups = "drop")
df_ost <- merge(rts_summary, pred, by = c("story","zone_id"), sort=F)

set.seed(1337)

messagef <- function(...) { message(sprintf(...)); flush.console() }

sig_code <- function(p) {
  if (is.na(p) || p >= 0.05) ""
  else if (p >= 0.01) "*"
  else if (p >= 0.001) "**"
  else "***"
}

run_cv_targets <- function(
    df,
    baseline_str,
    targets,
    output_path,
    n_folds = 10L,
    num_perm = 20000L,
    include_intercept = TRUE
){
  stopifnot(is.data.frame(df))
  stopifnot(is.character(baseline_str), length(baseline_str) == 1L)
  if (!("mean_RT" %in% names(df))) stop("df must contain mean_RT")

  base_f <- stats::as.formula(baseline_str)

  n <- nrow(df)
  if (n < n_folds) stop("nrow(df) must be >= n_folds")
  y <- df$mean_RT

  messagef("[START] n=%d folds=%d", n, n_folds)

  fold_ids <- sample(rep(seq_len(n_folds), length.out = n))


  mu_base <- numeric(n)
  sd_base <- numeric(n)

  for (f in seq_len(n_folds)) {
    te_idx <- which(fold_ids == f)
    tr_idx <- which(fold_ids != f)
    tr <- df[tr_idx, , drop = FALSE]
    te <- df[te_idx, , drop = FALSE]

    m_base <- stats::lm(base_f, data = tr)
    mu_base[te_idx] <- stats::predict(m_base, newdata = te)
    sd_base[te_idx] <- stats::sigma(m_base)
  }

  ll_base <- stats::dnorm(y, mean = mu_base, sd = sd_base, log = TRUE)

  all_perf <- list()
  all_coef <- list()

  for (tg in targets) {
    add_terms <- tg$add
    rhs_add <- paste(add_terms, collapse = " + ")
    targ_f <- stats::update(base_f, paste0(". ~ . + ", rhs_add))

    mu_targ <- numeric(n)
    sd_targ <- numeric(n)

    messagef("  - Target: %s", tg$name)

    m_full <- stats::lm(targ_f, data = df)

    fold_coefs <- vector("list", n_folds)

    for (f in seq_len(n_folds)) {
      te_idx <- which(fold_ids == f)
      tr_idx <- which(fold_ids != f)
      tr <- df[tr_idx, , drop = FALSE]
      te <- df[te_idx, , drop = FALSE]

      m_targ <- stats::lm(targ_f, data = tr)

      mu_targ[te_idx] <- stats::predict(m_targ, newdata = te)
      sd_targ[te_idx] <- stats::sigma(m_targ)

      cf <- stats::coef(m_targ)
      if (!include_intercept) cf <- cf[names(cf) != "(Intercept)"]
      fold_coefs[[f]] <- cf
    }

    ll_targ <- stats::dnorm(y, mean = mu_targ, sd = sd_targ, log = TRUE)
    dll <- ll_targ - ll_base

    pt_res <- jmuOutlier::perm.test(dll, alternative = "greater", num.sim = num_perm)
    pvalue <- pt_res$p.value

    m_dll <- mean(dll, na.rm = TRUE)
    se_dll <- plotrix::std.error(dll, na.rm = TRUE)

    all_perf[[length(all_perf) + 1L]] <- data.frame(
      predictor        = tg$name,
      mean_dll         = m_dll,
      lower_ci         = m_dll - 1.96 * se_dll,
      upper_ci         = m_dll + 1.96 * se_dll,
      p_value          = pvalue,
      sig              = sig_code(pvalue),
      stringsAsFactors = FALSE
    )

    all_terms <- sort(unique(unlist(lapply(fold_coefs, names))))
    coef_mat <- matrix(NA_real_, nrow = n_folds, ncol = length(all_terms))
    colnames(coef_mat) <- all_terms

    for (f in seq_len(n_folds)) {
      cf <- fold_coefs[[f]]
      coef_mat[f, names(cf)] <- unname(cf)
    }

    mean_coefs <- colMeans(coef_mat, na.rm = TRUE)

    all_coef[[length(all_coef) + 1L]] <- data.frame(
      predictor  = tg$name,
      term       = names(mean_coefs),
      mean_coef  = as.numeric(mean_coefs),
      stringsAsFactors = FALSE
    )
  }
  
  perf_df <- do.call(rbind, all_perf)
  coef_df <- do.call(rbind, all_coef)

  out <- coef_df %>%
    left_join(perf_df, by = "predictor") %>%
    arrange(predictor, term)
  
  utils::write.csv(out, file = output_path, row.names = FALSE)
  invisible(out)
}


run_cv_targets(
  df_ns,
  baseline_str = "mean_RT ~ zone + position + wlen + unisurp + surp + wlen_so1 + unisurp_so1 + surp_so1",
  targets = list(
    list(name="bert", add = c("bertstor","bertstor_so1"))
  ),
  output_path  = "../result/dll-across-models/ns_spr_bert.csv",
  n_folds       = 10L,
  num_perm      = 20000L,
  include_intercept = TRUE
)
run_cv_targets(
  df_ns,
  baseline_str = "mean_RT ~ zone + position + wlen + unisurp + surp + wlen_so1 + unisurp_so1 + surp_so1",
  targets = list(
    list(name="bertlarge", add = c("bertlargestor","bertlargestor_so1"))
  ),
  output_path  = "../result/dll-across-models/ns_spr_bertlarge.csv",
  n_folds       = 10L,
  num_perm      = 20000L,
  include_intercept = TRUE
)
run_cv_targets(
  df_ns,
  baseline_str = "mean_RT ~ zone + position + wlen + unisurp + surp + wlen_so1 + unisurp_so1 + surp_so1",
  targets = list(
    list(name="roberta", add = c("robertastor","robertastor_so1"))
  ),
  output_path  = "../result/dll-across-models/ns_spr_roberta.csv",
  n_folds       = 10L,
  num_perm      = 20000L,
  include_intercept = TRUE
)


run_cv_targets(
  df_ns_maze,
  baseline_str = "mean_RT ~ zone + position + wlen + unisurp + surp + wlen_so1 + unisurp_so1 + surp_so1",
  targets = list(
    list(name="bert", add = c("bertstor","bertstor_so1"))
  ),
  output_path  = "../result/dll-across-models/ns_maze_bert.csv",
  n_folds       = 10L,
  num_perm      = 20000L,
  include_intercept = TRUE
)
run_cv_targets(
  df_ns_maze,
  baseline_str = "mean_RT ~ zone + position + wlen + unisurp + surp + wlen_so1 + unisurp_so1 + surp_so1",
  targets = list(
    list(name="bertlarge", add = c("bertlargestor","bertlargestor_so1"))
  ),
  output_path  = "../result/dll-across-models/ns_maze_bertlarge.csv",
  n_folds       = 10L,
  num_perm      = 20000L,
  include_intercept = TRUE
)
run_cv_targets(
  df_ns_maze,
  baseline_str = "mean_RT ~ zone + position + wlen + unisurp + surp + wlen_so1 + unisurp_so1 + surp_so1",
  targets = list(
    list(name="roberta", add = c("robertastor","robertastor_so1"))
  ),
  output_path  = "../result/dll-across-models/ns_maze_roberta.csv",
  n_folds       = 10L,
  num_perm      = 20000L,
  include_intercept = TRUE
)

run_cv_targets(
  df_osfp,
  baseline_str = "mean_RT ~ zone + position + wlen + unisurp + surp + wlen_so1 + unisurp_so1 + surp_so1",
  targets = list(
    list(name="bert", add = c("bertstor","bertstor_so1"))
  ),
  output_path  = "../result/dll-across-models/osfp_bert.csv",
  n_folds       = 10L,
  num_perm      = 20000L,
  include_intercept = TRUE
)
run_cv_targets(
  df_osfp,
  baseline_str = "mean_RT ~ zone + position + wlen + unisurp + surp + wlen_so1 + unisurp_so1 + surp_so1",
  targets = list(
    list(name="bertlarge", add = c("bertlargestor","bertlargestor_so1"))
  ),
  output_path  = "../result/dll-across-models/osfp_bertlarge.csv",
  n_folds       = 10L,
  num_perm      = 20000L,
  include_intercept = TRUE
)
run_cv_targets(
  df_osfp,
  baseline_str = "mean_RT ~ zone + position + wlen + unisurp + surp + wlen_so1 + unisurp_so1 + surp_so1",
  targets = list(
    list(name="roberta", add = c("robertastor","robertastor_so1"))
  ),
  output_path  = "../result/dll-across-models/osfp_roberta.csv",
  n_folds       = 10L,
  num_perm      = 20000L,
  include_intercept = TRUE
)


run_cv_targets(
  df_osgp,
  baseline_str = "mean_RT ~ zone + position + wlen + unisurp + surp + wlen_so1 + unisurp_so1 + surp_so1",
  targets = list(
    list(name="bert", add = c("bertstor","bertstor_so1"))
  ),
  output_path  = "../result/dll-across-models/osgp_bert.csv",
  n_folds       = 10L,
  num_perm      = 20000L,
  include_intercept = TRUE
)
run_cv_targets(
  df_osgp,
  baseline_str = "mean_RT ~ zone + position + wlen + unisurp + surp + wlen_so1 + unisurp_so1 + surp_so1",
  targets = list(
    list(name="bertlarge", add = c("bertlargestor","bertlargestor_so1"))
  ),
  output_path  = "../result/dll-across-models/osgp_bertlarge.csv",
  n_folds       = 10L,
  num_perm      = 20000L,
  include_intercept = TRUE
)
run_cv_targets(
  df_osgp,
  baseline_str = "mean_RT ~ zone + position + wlen + unisurp + surp + wlen_so1 + unisurp_so1 + surp_so1",
  targets = list(
    list(name="roberta", add = c("robertastor","robertastor_so1"))
  ),
  output_path  = "../result/dll-across-models/osgp_roberta.csv",
  n_folds       = 10L,
  num_perm      = 20000L,
  include_intercept = TRUE
)



run_cv_targets(
  df_ost,
  baseline_str = "mean_RT ~ zone + position + wlen + unisurp + surp + wlen_so1 + unisurp_so1 + surp_so1",
  targets = list(
    list(name="bert", add = c("bertstor","bertstor_so1"))
  ),
  output_path  = "../result/dll-across-models/ost_bert.csv",
  n_folds       = 10L,
  num_perm      = 20000L,
  include_intercept = TRUE
)
run_cv_targets(
  df_ost,
  baseline_str = "mean_RT ~ zone + position + wlen + unisurp + surp + wlen_so1 + unisurp_so1 + surp_so1",
  targets = list(
    list(name="bertlarge", add = c("bertlargestor","bertlargestor_so1"))
  ),
  output_path  = "../result/dll-across-models/ost_bertlarge.csv",
  n_folds       = 10L,
  num_perm      = 20000L,
  include_intercept = TRUE
)
run_cv_targets(
  df_ost,
  baseline_str = "mean_RT ~ zone + position + wlen + unisurp + surp + wlen_so1 + unisurp_so1 + surp_so1",
  targets = list(
    list(name="roberta", add = c("robertastor","robertastor_so1"))
  ),
  output_path  = "../result/dll-across-models/ost_roberta.csv",
  n_folds       = 10L,
  num_perm      = 20000L,
  include_intercept = TRUE
)


sig_code <- function(p) {
  if (is.na(p) || p >= 0.05) ""
  else if (p >= 0.01) "*"
  else if (p >= 0.001) "**"
  else "***"
}
dataset_map <- list(
  "NS SPR"    = "../result/dll-across-models/ns_spr",
  "NS A-Maze" = "../result/dll-across-models/ns_maze",
  "OS FPD"    = "../result/dll-across-models/osfp",
  "OS GPD"    = "../result/dll-across-models/osgp",
  "OS TFD"    = "../result/dll-across-models/ost"
)

df_dll <- bind_rows(lapply(names(dataset_map), function(dname) {
  prefix <- dataset_map[[dname]]

  d_bert <- read_csv(paste0(prefix, "_bert.csv"), show_col_types = FALSE) %>%
    mutate(model = "BERT")
  
  d_bertlarge <- read_csv(paste0(prefix, "_bertlarge.csv"), show_col_types = FALSE) %>%
    mutate(model = "BERT-Large")
  
  d_roberta <- read_csv(paste0(prefix, "_roberta.csv"), show_col_types = FALSE) %>%
    mutate(model = "RoBERTa")

  bind_rows(d_bert, d_bertlarge, d_roberta) %>%
    select(model, mean_dll, lower_ci, upper_ci, p_value, sig) %>%
    distinct() %>%
    mutate(dataset = dname)
}))

all_pvalues <- df_dll$p_value
df_dll$p_adjusted <- p.adjust(all_pvalues, method = "BH")
df_dll$sig_adjusted <- sapply(df_dll$p_adjusted, sig_code)
df_dll$dataset <- factor(df_dll$dataset, levels = names(dataset_map))
df_dll$model <- factor(df_dll$model, levels = c("BERT", "BERT-Large", "RoBERTa"))


df_coef <- bind_rows(lapply(names(dataset_map), function(dname) {
  prefix <- dataset_map[[dname]]

  d_bert <- read_csv(paste0(prefix, "_bert.csv"), show_col_types = FALSE) %>%
    filter(term %in% c("bertstor", "bertstor_so1")) %>%
    mutate(
      model = "BERT",
      term_label = if_else(term == "bertstor", "Main", "Spillover")
    )

  d_bertlarge <- read_csv(paste0(prefix, "_bertlarge.csv"), show_col_types = FALSE) %>%
    filter(term %in% c("bertlargestor", "bertlargestor_so1")) %>%
    mutate(
      model = "BERT-Large",
      term_label = if_else(term == "bertlargestor", "Main", "Spillover")
    )

  d_roberta <- read_csv(paste0(prefix, "_roberta.csv"), show_col_types = FALSE) %>%
    filter(term %in% c("robertastor", "robertastor_so1")) %>%
    mutate(
      model = "RoBERTa",
      term_label = if_else(term == "robertastor", "Main", "Spillover")
    )
  
  bind_rows(d_bert, d_bertlarge, d_roberta) %>%
    mutate(dataset = dname)
}))
df_coef$dataset <- factor(df_coef$dataset, levels = names(dataset_map))
df_coef$model <- factor(df_coef$model, levels = c("BERT", "BERT-Large", "RoBERTa"))
df_coef$term_label <- factor(df_coef$term_label, levels = c("Main", "Spillover"))
df_coef <- df_coef %>%
  mutate(group_id = interaction(model, term_label, sep = "-"))
df_coef$group_id <- factor(df_coef$group_id, levels = c(
  "BERT-Main", "BERT-Spillover",
  "BERT-Large-Main", "BERT-Large-Spillover",
  "RoBERTa-Main", "RoBERTa-Spillover"
))


pd <- position_dodge(width = 0.8)
color_palette <- c(
  "BERT"        = "#0072B2",
  "BERT-Large"  = "#E69F00",
  "RoBERTa"     = "#009E73"
)
shape_palette <- c(
  "BERT"        = 21,
  "BERT-Large" = 21,
  "RoBERTa" = 21
)
fill_palette <- c(
  "BERT"        = "#0072B2",
  "BERT-Large"  = "#E69F00",
  "RoBERTa"     = "#009E73"
)
p1 <- ggplot(df_dll, aes(x = dataset, y = mean_dll, color = model, shape = model, fill = model, group = model)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_pointrange(aes(ymin = lower_ci, ymax = upper_ci), size = 0.8, position = pd) +
  geom_text(aes(label = sig_adjusted, y = upper_ci), position = pd, vjust = -0.1, size = 4, show.legend = FALSE) +
  labs(
    x = NULL,
    y = "Delta Log-Likelihood (average per word)",
    color = "",
    shape = "",
    fill = "",
  ) +
  scale_color_manual(values = color_palette) +
  scale_shape_manual(values = shape_palette) +
  scale_fill_manual(values = fill_palette) +
  theme_bw() +
  theme(
    axis.text.x = element_text(angle = 0, hjust = 0.5, size = 12),
    axis.title.y = element_text(size = 12.5),
    legend.position = "bottom",
    legend.text = element_text(size = 12.5)
  )

ggsave("../result/png/dll_infostors.png", plot = p1, width = 6, height = 4, dpi = 600)
ggsave("../result/pdf/dll_infostors.pdf", plot = p1, width = 6, height = 4)



legend_labels <- c(
  "BERT-Main"       = "BERT (Current)",
  "BERT-Spillover"  = "BERT (Spillover)",
  "BERT-Large-Main"      = "BERT-Large (Current)",
  "BERT-Large-Spillover" = "BERT-Large (Spillover)",
  "RoBERTa-Main"       = "RoBERTa (Current)",
  "RoBERTa-Spillover"  = "RoBERTa (Spillover)"
)

p2 <- ggplot(df_coef, aes(x = dataset, y = mean_coef, fill = group_id, color = group_id)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_bar(stat = "identity", position = position_dodge(width = 0.77), width = 0.7, linewidth = 0.7) +
  
  labs(
    x = NULL,
    y = "Coefficient Estimate",
    fill = "",
    color = ""
  ) +
  scale_color_manual(
    values = c(
      "BERT-Main"       = "#0072B2",
      "BERT-Spillover"  = "#0072B2",
      "BERT-Large-Main"      = "#E69F00",
      "BERT-Large-Spillover" = "#E69F00",
      "RoBERTa-Main"       = "#009E73",
      "RoBERTa-Spillover"  = "#009E73"
    ),
    labels = legend_labels,
    name = ""
  ) +
  
  scale_fill_manual(
    values = c(
      "BERT-Main"       = "#0072B2",
      "BERT-Spillover"  = "white",
      "BERT-Large-Main"      = "#E69F00",
      "BERT-Large-Spillover" = "white",
      "RoBERTa-Main"       = "#009E73",
      "RoBERTa-Spillover"  = "white"
    ),
    labels = legend_labels,
    name = ""
  ) +
  
  theme_bw() +
  theme(
    axis.text.x = element_text(hjust = 0.5, size = 12),
    axis.title.y = element_text(size = 12.5),
    legend.position = "bottom",
    legend.text = element_text(size = 11),
    legend.box.margin = margin(t = -5)
  )

ggsave("../result/png/coef_inforstors.png", plot = p2, width = 6, height = 4, dpi = 600)
ggsave("../result/pdf/coef_inforstors.pdf", plot = p2, width = 6, height = 4)
