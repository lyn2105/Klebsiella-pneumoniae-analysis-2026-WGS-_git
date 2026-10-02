library(jsonlite); library(dplyr); library(purrr); library(openxlsx)

dir <- "/mnt/Users/tbinh_workspace/ThesisDataMGI/01_qc/fastp_20260930"
out <- "/mnt/Users/tbinh_workspace/ThesisDataMGI/01_qc"
files <- list.files(dir, pattern = "_fastp\\.json$", full.names = TRUE)

gc_of <- function(rd) {
  cc <- rd$content_curves
  g <- if (!is.null(cc$mean_gc)) unlist(cc$mean_gc) else unlist(cc$G) + unlist(cc$C)
  mean(g) * 100
}

stat <- function(rd) {
  tibble(reads = rd$total_reads,
         bases = rd$total_bases,
         len   = rd$total_bases / rd$total_reads,
         gc    = gc_of(rd),
         q20   = rd$q20_bases / rd$total_bases * 100,
         q30   = rd$q30_bases / rd$total_bases * 100)
}

## Bảng 3.1: từng mẫu, R1/R2, trước và sau làm sạch
bang31 <- map_dfr(files, function(f) {
  j <- fromJSON(f, simplifyVector = FALSE)
  s <- sub("_fastp\\.json$", "", basename(f))
  map_dfr(c("1", "2"), function(k) {
    b <- stat(j[[paste0("read", k, "_before_filtering")]]) %>% rename_with(~ paste0("truoc_", .x))
    a <- stat(j[[paste0("read", k, "_after_filtering")]])  %>% rename_with(~ paste0("sau_",   .x))
    bind_cols(tibble(Sample = paste0(sub(".*_", "", s), "_", k)), b, a)
  })
})

bang31 <- bang31 %>% mutate(across(where(is.numeric), ~ round(.x, 2)))

## Bảng 3.2: thống kê mô tả sau làm sạch
per_sample <- map_dfr(files, function(f) {
  j  <- fromJSON(f, simplifyVector = FALSE)
  a1 <- j$read1_after_filtering; a2 <- j$read2_after_filtering
  n0 <- j$read1_before_filtering$total_reads + j$read2_before_filtering$total_reads
  tibble(sample = sub("_fastp\\.json$", "", basename(f)),
         reads = a1$total_reads,
         bases = a1$total_bases,
         len   = (as.numeric(a1$total_bases) + a2$total_bases) / (as.numeric(a1$total_reads) + a2$total_reads),
         gc    = (gc_of(a1) + gc_of(a2)) / 2,
         q20   = (as.numeric(a1$q20_bases) + a2$q20_bases) / (as.numeric(a1$total_bases) + a2$total_bases) * 100,
         q30   = (as.numeric(a1$q30_bases) + a2$q30_bases) / (as.numeric(a1$total_bases) + a2$total_bases) * 100,
         trung_lap       = j$duplication$rate * 100,
         chat_luong_thap = j$filtering_result$low_quality_reads / n0 * 100,
         chua_N          = j$filtering_result$too_many_N_reads  / n0 * 100,
         qua_ngan        = j$filtering_result$too_short_reads   / n0 * 100)
})

chi_so <- c(reads = "Tổng số read (read/mẫu)", bases = "Tổng số base (bp/mẫu)",
            len = "Độ dài read trung bình (bp)", gc = "%GC", q20 = "%Q20", q30 = "%Q30",
            trung_lap = "Tỷ lệ read trùng lặp (%)",
            chat_luong_thap = "Tỷ lệ read chất lượng thấp (%)",
            chua_N = "Tỷ lệ read chứa N (%)", qua_ngan = "Tỷ lệ read quá ngắn (%)")
dgt <- c(reads = 0, bases = 0, len = 1, gc = 2, q20 = 2, q30 = 2,
         trung_lap = 2, chat_luong_thap = 2, chua_N = 4, qua_ngan = 3)
fm <- function(x, d) formatC(x, format = "f", digits = d, big.mark = ",")

bang32 <- tibble(
  `Chỉ số` = unname(chi_so),
  `Trung bình ± SD` = map_chr(names(chi_so), ~ paste0(fm(mean(per_sample[[.x]]), dgt[.x]), " ± ", fm(sd(per_sample[[.x]]), dgt[.x]))),
  `Trung vị`        = map_chr(names(chi_so), ~ fm(median(per_sample[[.x]]), dgt[.x])),
  `Min – Max`       = map_chr(names(chi_so), ~ paste0(fm(min(per_sample[[.x]]), dgt[.x]), " – ", fm(max(per_sample[[.x]]), dgt[.x])))
)

print(bang32)
write.xlsx(list(Bang_3.1 = bang31, Bang_3.2 = bang32, Theo_mau = per_sample),
           file.path(out, "Bang_QC_fastp.xlsx"))
cat("Xong:", file.path(out, "Bang_QC_fastp.xlsx"), "\n")
