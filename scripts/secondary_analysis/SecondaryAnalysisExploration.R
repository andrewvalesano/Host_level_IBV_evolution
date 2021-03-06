
### Project: IBV
### Purpose: Some initial analysis of iSNVs. Explore the data.
### Working directory: Host_level_IBV_evolution

# =========== Import packages, load data ================

library(tidyverse)
library(wesanderson)
library(ggbeeswarm)
palette <- wesanderson::wes_palette("FantasticFox1")

meta <- read_csv("data/metadata/flu_b_2010_2017_v4LONG_withSeqInfo_gc.csv")
meta_v5 <- read_csv("data/metadata/flu_b_2010_2017_v5LONG_withSeqInfo_gc.csv")
meta_short <- read_csv("data/metadata/flu_b_2010_2017_v4.csv")
metadata_by_seq <- read_csv("data/metadata/Metadata_By_Seq_withALVID.csv")
quality_var <- read_csv("data/processed/qual.snv.csv")
no_freq_cut_var <- read_csv("data/processed/no_freq_cut.qual.snv.csv")
qual_not_coll <- read_csv("data/processed/qual.not.collapsed.snv.csv")
chrs <- read.csv("data/metadata/ibv.segs.csv", stringsAsFactors = TRUE)
IAV_snv_qual_meta <- read_csv("data/processed/IAV_snv_qual_meta.csv")

plot.median <- function(x) {
  m <- median(x)
  c(y = m, ymin = m, ymax = m)
}

# =========== Filters for 2% cutoff ================

nocut_isnv <- filter(no_freq_cut_var, freq.var < 0.98) # 8693 variants
isnv <- filter(quality_var, freq.var < 0.98) # 136 variants
isnv_nomixed <- filter(isnv, !(ENROLLID %in% c("50425")))
isnv_minority <- filter(quality_var, freq.var < 0.5) # 68 variants below 50%

ggplot(isnv, aes(freq.var)) + geom_histogram(binwidth = 0.01)
ggplot(nocut_isnv, aes(freq.var)) + geom_histogram(binwidth = 0.0001) + xlim(0, 0.02) + geom_vline(xintercept = 0.02, linetype = "dotted", color = "black", size = 1) # Mostly with very low frequencies, even though seen in both samples. Almost all below 0.5%.

# =========== Titer by DPSO ================

titer.plot <- ggplot(meta, aes(x = as.factor(DPSO), y = genome_copy_per_ul)) + geom_boxplot(notch = TRUE) + ylab(expression(paste(Genomes,"/" ,mu,L))) + scale_y_log10() + xlab("Days Post Symptom Onset") + theme_bw() + theme(text = element_text(size = 35), axis.text.x = element_text(size = 25), axis.text.y = element_text(size = 25))
titer.plot.scatter <- ggplot(meta, aes(x = DPSO, y = genome_copy_per_ul)) + geom_point() + ylab(expression(paste(Genomes,"/" , mu, L))) + scale_y_log10() + xlab("Days Post Symptom Onset") + theme_bw()

#ggsave(plot = titer.plot, filename = "results/plots/TiterByDPSO_box.jpg", device = "jpeg")
#ggsave(plot = titer.plot.scatter, filename = "results/plots/TiterByDPSO_scatter.jpg", device = "jpeg")
ggsave(plot = titer.plot, filename = "results/plots/TiterByDPSO_box.pdf", device = "pdf", width = 10, height = 10)
ggsave(plot = titer.plot.scatter, filename = "results/plots/TiterByDPSO_scatter.pdf", device = "pdf")

# =========== iSNV by DPSO ================

isnv_minority_nomixed <- filter(isnv_minority, !(ENROLLID %in% c("50425"))) # remove mixed infections

isnv_minority %>% group_by(ALV_ID) %>% dplyr::summarize(iSNV = length(unique(mutation)), HA_iSNV = length(which(chr == "HA")), nonsyn_snv = length(which(class_factor == "Nonsynonymous")), syn_snv = length(which(class_factor == "Synonymous"))) -> isnv_minority_count
meta_snv <- filter(meta, coverage_qualified == TRUE)
meta_snv <- merge(meta_snv, isnv_minority_count, by="ALV_ID", all.x = TRUE)
meta_snv$iSNV[is.na(meta_snv$iSNV)] <- 0 # NA means there were no variants; change to 0
meta_snv$nonsyn_snv[is.na(meta_snv$nonsyn_snv)] <- 0
meta_snv$syn_snv[is.na(meta_snv$syn_snv)] <- 0

write_csv(meta_snv, "data/processed/meta_snv.csv")

isnv_by_day.plot <- ggplot(meta_snv, aes(x = as.factor(DPSO), y = iSNV)) + geom_boxplot(outlier.shape = NA, notch = FALSE) + xlab("Day Post Symptom Onset") + 
  geom_jitter(width = 0.3, height = 0.1, size = 3.5) + theme_bw() + ylab("iSNV Per Sample")
ggsave(plot = isnv_by_day.plot, filename = "results/plots/SNVbyDPSO.jpg", device = "jpeg")
ggsave(plot = isnv_by_day.plot, filename = "results/plots/SNVbyDPSO.pdf", device = "pdf")

isnv_by_day.plot <- isnv_by_day.plot + theme(text = element_text(size = 35), axis.text.x = element_text(size = 20), axis.text.y = element_text(size = 20))
ggsave(plot = isnv_by_day.plot, filename = "results/plots/SNVbyDPSO_square.pdf", device = "pdf", width = 10, height = 10)

# ============ Select data for table ==================

isnv_minority_nomixed %>% mutate(coverage = cov.tst.fw + cov.tst.bw) %>% select(ENROLLID, ALV_ID, coverage, chr, mutation, Var_AA, freq.var, class_factor, season, vaccination_status, is_home_spec, genome_copy_per_ul, pcr_result) -> isnv_minority_nomixed_table
isnv_minority %>% filter(ENROLLID == "50425") %>% mutate(coverage = cov.tst.fw + cov.tst.bw) %>% select(ENROLLID, ALV_ID, coverage, chr, mutation, Var_AA, freq.var, class_factor, season, vaccination_status, is_home_spec, genome_copy_per_ul, pcr_result) -> isnv_minority_mixedinfection_table

# =========== iSNV counts per sample ================

isnv.per.sample <- ggplot(meta_snv, aes(x = iSNV)) + geom_histogram(binwidth = 1, fill = palette[5], color = "white") + xlab("Number of iSNV (Bin Width = 1)") + ylab("Number of samples") + theme_bw()
#ggsave(plot = isnv.per.sample, filename = "results/plots/SNVperSample.jpg", device = "jpeg")
ggsave(plot = isnv.per.sample, filename = "results/plots/SNVperSample.pdf", device = "pdf")

# Compare to IAV data
IBV_snv <- select(meta_snv, iSNV)
IBV_snv <- mutate(IBV_snv, type = "Influenza B")
IAV_snv <- select(IAV_snv_qual_meta, iSNV)
IAV_snv <- mutate(IAV_snv, type = "Influenza A")
cfIAV_data <- rbind(IBV_snv, IAV_snv)

cfIAV.plot.identity <- ggplot(cfIAV_data, aes(x = iSNV, fill = type)) + geom_histogram(binwidth = 1, alpha = 0.5, color = "white", position = "identity") + scale_fill_manual(name = "Type", values = c(palette[3], palette[5])) + xlab("Number of iSNV") + ylab("Number of samples") + theme_bw()
cfIAV.plot.dodge <- ggplot(cfIAV_data, aes(x = iSNV, fill = type)) + geom_histogram(binwidth = 1, alpha = 1, color = "white", position = "dodge") + scale_fill_manual(name = "Type", values = c(palette[3], palette[5])) + xlab("Number of iSNV") + ylab("Number of samples") + theme_bw()

cfIAV.dotplot <- ggplot(cfIAV_data, aes(y = iSNV, x = as.factor(type), fill = type, color = type)) +
  geom_dotplot(stackdir = "center", binaxis = 'y', binwidth = 1, dotsize = 0.4) + scale_fill_manual(values = c("black", palette[5])) + scale_color_manual(values = c("black", palette[5])) +
  #stat_summary(fun.data = "plot.median", geom = "errorbar", colour = "red", width = 0.95, size = 0.3) +
  xlab("") + ylab("iSNV Per Sample") + theme_bw() + theme(legend.position = "")

#ggsave(plot = cfIAV.plot.identity, filename = "results/plots/SNVperSample_cfIAV_identity.jpg", device = "jpeg")
#ggsave(plot = cfIAV.plot.dodge, filename = "results/plots/SNVperSample_cfIAV_dodge.jpg", device = "jpeg")
ggsave(plot = cfIAV.plot.identity, filename = "results/plots/SNVperSample_cfIAV_identity.pdf", device = "pdf")
ggsave(plot = cfIAV.plot.dodge, filename = "results/plots/SNVperSample_cfIAV_dodge.pdf", device = "pdf")
ggsave(plot = cfIAV.dotplot, filename = "results/plots/SNVperSample_cfIAV_dotplot.pdf", device = "pdf")

cfIAV.dotplot <- cfIAV.dotplot + theme(text = element_text(size = 35), axis.text.x = element_text(size = 32), axis.text.y = element_text(size = 28))
ggsave(plot = cfIAV.dotplot, filename = "results/plots/SNVperSample_cfIAV_dotplot_square.pdf", device = "pdf", width = 4, height = 4)

# Remove mixed infections and test
meta_snv_nomixed <- filter(meta_snv, ENROLLID != "50425")
IBV_snv <- select(meta_snv_nomixed, iSNV)
IBV_snv <- mutate(IBV_snv, type = "Influenza B")
IAV_snv_qual_meta_nomixed <- filter(IAV_snv_qual_meta, !SPECID %in% c("HS1530", "M54062" ,"MH8125", "MH8137" ,"MH8156" ,"MH8390"))
IAV_snv <- select(IAV_snv_qual_meta_nomixed, iSNV)
IAV_snv <- mutate(IAV_snv, type = "Influenza A")
cfIAV_data <- rbind(IBV_snv, IAV_snv)

t.test(IBV_snv$iSNV, IAV_snv$iSNV)
wilcox.test(IBV_snv$iSNV, IAV_snv$iSNV)

# summary stats

median(IBV_snv_2$iSNV)
quantile(IBV_snv_2$iSNV)
nrow(filter(IBV_snv_2, iSNV == 0)) / nrow(IBV_snv_2)

median(IAV_snv_2$iSNV)
quantile(IAV_snv_2$iSNV)
nrow(filter(IAV_snv_2, iSNV == 0)) / nrow(IAV_snv_2)

# Other stats
snv.by.dpso.anova <- aov(iSNV ~ DPSO, data = meta_snv_nomixed)


# Yam vs. Vic

Vic_Yam_plot <- ggplot(meta_snv, aes(y = iSNV, x = as.factor(pcr_result))) +
  geom_dotplot(stackdir = "center", binaxis = 'y', binwidth = 1, dotsize = 0.3) +
  xlab("") + 
  ylab("iSNV Per Sample") + 
  theme_bw() + 
  theme(legend.position = "")

# =========== iSNV frequency by genome position ================

positions <- read_csv("./data/processed/FluSegmentPositions.csv") # lengths from reference files
positions_YAM <- filter(positions, Lineage == "B/YAM")

isnv_minority_nomixed_concatpos <- mutate(isnv_minority_nomixed, concat_pos = positions_YAM$AddLength[match(chr, positions_YAM$Segment)] + pos)

freq.by.pos <- ggplot(isnv_minority_nomixed_concatpos, aes(x = concat_pos, y = freq.var, fill = class_factor)) +
  geom_point(size = 3, shape = 21) +
  scale_fill_manual(values = palette[c(3,4)]) +
  theme_bw() + 
  xlab("Concatenated Genome Position") + 
  ylab("Frequency") +
  theme(legend.position = "none", panel.grid.minor = element_blank()) +
  scale_x_continuous(labels = positions_YAM$Segment, breaks = positions_YAM$AddLength)

# 10 by 4

# =========== iSNV counts per sample by genome copy number ================

snv_by_copynum <- ggplot(meta_snv, aes(x = log(genome_copy_per_ul, 10), y = iSNV)) + geom_point(shape = 19, size = 3.5) + 
  ylab("iSNV Per Sample") + theme_bw() +
  #geom_vline(xintercept = 5, linetype = "dotted", color = palette[5], size = 1.5) +
  xlab(expression(paste("Log (base 10) of genomes/", mu, L)))
snv_by_gc <- lm(data = meta_snv, formula = iSNV ~ log(genome_copy_per_ul, 10))
summary(snv_by_gc)
#ggsave(plot = snv_by_copynum, filename = "results/plots/SNVbyCopyNumber.jpg", device = "jpeg")
ggsave(plot = snv_by_copynum, filename = "results/plots/SNVbyCopyNumber.pdf", device = "pdf")

snv_by_copynum <- snv_by_copynum + theme(text = element_text(size = 35), axis.text.x = element_text(size = 25), axis.text.y = element_text(size = 25))
ggsave(plot = snv_by_copynum, filename = "results/plots/SNVbyCopyNumber_square.pdf", device = "pdf", width = 10, height = 10)

# =========== iSNV counts by vaccination status ================

isnv_by_vaccination <- ggplot(meta_snv, aes(y = iSNV, x = as.factor(vaccination_status))) +
  geom_dotplot(stackdir = "center", binaxis = 'y', binwidth = 1, dotsize = 0.25) +
  #stat_summary(fun.data = "plot.median", geom = "errorbar", colour = "red", width = 0.95, size = 0.3) +
  #scale_fill_manual(values = c(palette[5], palette[5])) + scale_color_manual(values = c(palette[5], palette[5])) +
  scale_x_discrete(labels = c("Not Vaccinated", "Vaccinated")) + xlab("") + theme_bw() + ylab("iSNV Per Sample") +
  theme(legend.position = "")

novax <- filter(meta_snv, vaccination_status == 0 & iSNV < 5)$iSNV
yesvax <- filter(meta_snv, vaccination_status == 1 & iSNV < 5)$iSNV
t.test(novax, yesvax)
wilcox.test(novax, yesvax)

#ggsave(plot = isnv_by_vaccination, filename = "results/plots/SNVbyVaccinationStatus.jpg", device = "jpeg")
#ggsave(plot = isnv_by_vaccination, filename = "results/plots/SNVbyVaccinationStatus.pdf", device = "pdf")

isnv_by_vaccination <- isnv_by_vaccination + theme(text = element_text(size = 35), axis.text.x = element_text(size = 32), axis.text.y = element_text(size = 28), axis.title.x = element_text(margin = margin(t = 20)))
ggsave(plot = isnv_by_vaccination, filename = "results/plots/SNVbyVaccinationStatus_square.pdf", device = "pdf", width = 10, height = 10)

# =========== iSNV counts by vaccination status: account for mismatches in trivalent vaccine recipients ================

meta_v5_snv <- filter(meta_v5, coverage_qualified == TRUE)
meta_v5_snv <- merge(meta_v5_snv, isnv_minority_count, by="ALV_ID", all.x = TRUE)
meta_v5_snv$iSNV[is.na(meta_v5_snv$iSNV)] <- 0 # NA means there were no variants; change to 0

meta_v5_modified <- filter(meta_v5_snv, valence != 9 | vaccination_status == 0)
meta_v5_modified_novax <- filter(meta_v5_modified, vaccination_status == 0)
meta_v5_modified_novax <- mutate(meta_v5_modified_novax, vaccination_status_new = vaccination_status)
meta_v5_modified_vax4 <- filter(meta_v5_modified, vaccination_status == 1 & valence == 4)
meta_v5_modified_vax4 <- mutate(meta_v5_modified_vax4, vaccination_status_new = vaccination_status)
meta_v5_modified_vax3 <- filter(meta_v5_modified, vaccination_status == 1 & valence == 3)
meta_v5_modified_vax3 <- mutate(meta_v5_modified_vax3, vaccination_status_new = vaccination_status)
meta_v5_modified_vax3 <- mutate(meta_v5_modified_vax3, vaccination_status_new = ifelse(season == "2011-2012" & pcr_result ==  "B/YAM", 0, vaccination_status_new))
meta_v5_modified_vax3 <- mutate(meta_v5_modified_vax3, vaccination_status_new = ifelse(season == "2012-2013" & pcr_result ==  "B/VIC", 0, vaccination_status_new))
meta_v5_modified_final <- rbind(meta_v5_modified_novax, meta_v5_modified_vax4, meta_v5_modified_vax3)

isnv_by_vaccination <- ggplot(meta_v5_modified_final, aes(y = iSNV, x = as.factor(vaccination_status_new))) +
  geom_dotplot(stackdir = "center", binaxis = 'y', binwidth = 1, dotsize = 0.25) +
  #stat_summary(fun.data = "plot.median", geom = "errorbar", colour = "red", width = 0.95, size = 0.3) +
  #scale_fill_manual(values = c(palette[5], palette[5])) + scale_color_manual(values = c(palette[5], palette[5])) +
  scale_x_discrete(labels = c("Not Vaccinated", "Vaccinated")) + xlab("") + theme_bw() + ylab("iSNV Per Sample") +
  theme(legend.position = "")

novax <- filter(meta_v5_modified_final, vaccination_status_new == 0)$iSNV
yesvax <- filter(meta_v5_modified_final, vaccination_status_new == 1)$iSNV
t.test(novax, yesvax)
wilcox.test(novax, yesvax)

# =========== iSNV across genome segments ================

isnv_minority_nomixed$chr <- factor(isnv_minority_nomixed$chr, levels = rev(c("PB2","PB1","PA","HA","NP","NR","M1","NS")))
chrs$chr <- factor(chrs$chr, levels = levels(isnv_minority_nomixed$chr))

antigenic_sites <- read_csv("data/processed/antigenic_positions.csv")
antigenic_sites <- filter(antigenic_sites, Lineage == "B/YAM")
antigenic_sites <- mutate(antigenic_sites, chr = "HA")

site_height = 0.25

# Excludes the mixed infection. 68 minority variants in all, 40 if you exclude the mixed infection. Then 4 HA NonSyn variants (all non antigenic).
genome_location.plot <- ggplot(isnv_minority_nomixed, aes(x = pos, y = chr)) +
  geom_point(aes(color = class_factor), shape = 108, size = 5) +
  geom_segment(data = chrs, aes(x = start, y = chr, xend = stop, yend = chr)) +
  annotate("rect", xmin = 429, xmax = 495, ymin = 1-site_height, ymax = 1+site_height, alpha = .2, color = "grey", fill = "grey") +
  annotate("rect", xmin = 504, xmax = 534, ymin = 1-site_height, ymax = 1+site_height, alpha = .2, color = "grey", fill = "grey") +
  annotate("rect", xmin = 567, xmax = 594, ymin = 1-site_height, ymax = 1+site_height, alpha = .2, color = "grey", fill = "grey") +
  annotate("rect", xmin = 669, xmax = 699, ymin = 1-site_height, ymax = 1+site_height, alpha = .2, color = "grey", fill = "grey") +
  ylab("") +
  xlab("") +
  scale_color_manual(name = "", values = palette[c(4,3)]) +
  theme(axis.ticks = element_blank(),
        axis.line.x = element_blank(), axis.line.y = element_blank()) +
  scale_x_continuous(breaks = c()) +
  theme_minimal() + theme(panel.grid.major = element_line(colour = "white")) + theme(legend.position = "")

#ggsave(plot = genome_location.plot, filename = "results/plots/SNVbyGenomeLocation.jpg", device = "jpeg")
ggsave(plot = genome_location.plot, filename = "results/plots/SNVbyGenomeLocation.pdf", device = "pdf", width = 4, height = 4)

# Mark minority SNV that are found in multiple individuals.

isnv_minority_nomixed %>% group_by(chr, pos, var, pcr_result, season) %>% dplyr::summarize(counts = length(unique(ENROLLID))) -> isnv_minority_nomixed_count
isnv_minority_nomixed <- mutate(isnv_minority_nomixed, scratch = paste(chr, pos, chr, var, season, pcr_result, sep = "."))
isnv_minority_nomixed_count <- mutate(isnv_minority_nomixed_count, scratch = paste(chr, pos, chr, var, season, pcr_result, sep = "."))
multiple <- subset(isnv_minority_nomixed, scratch %in% isnv_minority_nomixed_count$scratch[isnv_minority_nomixed_count$counts > 1])

genome_location.plot.multiple <- genome_location.plot + geom_point(data = multiple, aes(x = pos, y = as.numeric(chr) + 0.2, color = class_factor), size = 1, shape = 25)

#ggsave(plot = genome_location.plot.multiple, filename = "results/plots/SNVbyGenomeLocation_WithMultiple.jpg", device = "jpeg")
ggsave(plot = genome_location.plot.multiple, filename = "results/plots/SNVbyGenomeLocation_WithMultiple.pdf", device = "pdf")

# =========== Frequency by Nonsyn/Syn ================


freq_histogram <- ggplot(isnv_minority_nomixed, aes(x = freq.var, fill = class_factor)) + geom_histogram(color = "white", binwidth = 0.05, position = "dodge", boundary = 0.02) +
  xlab("Frequency") + ylab("Number of iSNV") +
  scale_fill_manual(name = "" , values = palette[c(4,3)])+
  theme(legend.position = c(0.5, 0.5)) + theme_classic()

#ggsave(plot = freq_histogram, filename = "results/plots/SNVbyFrequency.jpg", device = "jpeg")
ggsave(plot = freq_histogram, filename = "results/plots/SNVbyFrequency.pdf", device = "pdf", width = 5, height = 5)

# =========== Distribution of sampling times infections with home and clinic samples ================

meta_homeAndClinic <- filter(meta_short, home_spec == 1) # This is all flu B samples from HIVE. Need to filter by those that which we sequenced.
IDs_cov_qualified <- filter(meta, coverage_qualified == TRUE)
meta_homeAndClinic <- filter(meta_homeAndClinic, SPECID %in% IDs_cov_qualified$ALV_ID & home_spec_accn %in% IDs_cov_qualified$ALV_ID)

# Now calculate time between sampling.
meta_homeAndClinic %>% mutate(DPS1 = home_spec_date-onset, DPS2 = collect-onset) -> meta_homeAndClinic
meta_homeAndClinic <- meta_homeAndClinic[order(meta_homeAndClinic$DPS1, meta_homeAndClinic$DPS2, decreasing = TRUE),]
meta_homeAndClinic <- mutate(meta_homeAndClinic, DPS2 = ifelse(DPS1 == DPS2, yes = DPS2 + 0.3, no = DPS2)) 
meta_homeAndClinic$sort_order <- 1:nrow(meta_homeAndClinic)

sampling_distribution <- ggplot(meta_homeAndClinic, aes(x = DPS1, xend = DPS2, y = sort_order, yend = sort_order)) + geom_segment(color = palette[3]) + ylab("") +
  xlab("Day post symptom onset") +
  geom_point(aes(y = sort_order, x = DPS1), color = "black") +
  geom_point(aes(y = sort_order, x = DPS2), color = "black") + 
  scale_x_continuous(breaks = -2:6) + theme_classic() + theme(axis.line.y = element_blank(), axis.ticks.y = element_blank(), axis.text.y = element_blank())

#ggsave(plot = sampling_distribution, filename = "results/plots/SampleCollectionTimes.jpg", device = "jpeg")
ggsave(plot = sampling_distribution, filename = "results/plots/SampleCollectionTimes.pdf", device = "pdf", device = "pdf", width = 5, height = 5)

# =========== Concordance between sequencing replicates ================

# Get all variants from sequencing replicates of the same sample (whether it's a home or clinic sample). Draw variants from qual_not_coll.

isnv_not_collapsed <- filter(qual_not_coll, freq.var < 0.98)
#isnv_not_collapsed <- filter(isnv_not_collapsed, !(ENROLLID %in% c("50425"))) # remove mixed infection

isnv_not_collapsed_rep1 <- filter(isnv_not_collapsed, SampleNumber == SeqSampleNumber1)
isnv_not_collapsed_rep2 <- filter(isnv_not_collapsed, SampleNumber == SeqSampleNumber2)
isnv_not_collapsed_rep1 <- mutate(isnv_not_collapsed_rep1, mut_id = paste0(mutation, "_", ALV_ID))
isnv_not_collapsed_rep2 <- mutate(isnv_not_collapsed_rep2, mut_id = paste0(mutation, "_", ALV_ID))
merged <- merge(isnv_not_collapsed_rep1, isnv_not_collapsed_rep2, by = "mut_id")

merged_nomixed <- filter(merged, !(ALV_ID.x %in% c("HS1875", "MH10536")))

replicate_concordance_all <- ggplot(data = merged, aes(x = freq.var.x, y = freq.var.y)) +
  geom_point(aes(color = as.factor(floor(log10(genome_copy_per_ul.x))))) +
  geom_abline(slope = 1, intercept = 0, lty = 2) +
  scale_y_continuous(limits = c(0,0.5)) +
  scale_x_continuous(limits = c(0,0.5)) +
  xlab("Frequency in replicate 1") + ylab("Frequency in replicate 2") +
  scale_color_manual(name = "Log(copies/ul)", values = palette[c(4,3)]) + theme_bw()

replicate_concordance_no_mixed <- ggplot(data = merged_nomixed, aes(x = freq.var.x, y = freq.var.y)) +
  geom_point(aes(color = as.factor(floor(log10(genome_copy_per_ul.x))))) +
  geom_abline(slope = 1, intercept = 0, lty = 2) +
  scale_y_continuous(limits = c(0,0.5)) +
  scale_x_continuous(limits = c(0,0.5)) +
  xlab("Frequency in replicate 1") + ylab("Frequency in replicate 2") +
  scale_color_manual(name = "Log(copies/ul)", values = palette[c(4,3)]) + theme_bw()

#ggsave(plot = replicate_concordance_all, filename = "results/plots/ReplicateConcordance_All.jpg", device = "jpeg")
#ggsave(plot = replicate_concordance_no_mixed, filename = "results/plots/ReplicateConcordance_NoMixed.jpg", device = "jpeg")

ggsave(plot = replicate_concordance_all, filename = "results/plots/ReplicateConcordance_All.pdf", device = "pdf")
ggsave(plot = replicate_concordance_no_mixed, filename = "results/plots/ReplicateConcordance_NoMixed.pdf", device = "pdf", height = 5, width = 5)

# =========== Concordance between frequency in home and clinic isolates ================ 

### Few variants in each sample, few samples that have home and clinic sample on the same day.

meta_homeAndClinic <- filter(meta_short, home_spec == 1) # only those from which we have both home and clinic samples
meta_homeAndClinic <- mutate(meta_homeAndClinic, within_host_time = collect - home_spec_date)
#meta_homeAndClinic <- filter(meta_homeAndClinic, within_host_time == 0) # filter to specify within-host time
variants_home <- filter(isnv_minority_nomixed, ALV_ID %in% meta_homeAndClinic$home_spec_accn)
variants_clinic <- filter(isnv_minority_nomixed, ALV_ID %in% meta_homeAndClinic$SPECID)

variants_home %>% group_by(ALV_ID) %>% filter(mutation %in% variants_clinic$mutation) -> home
variants_clinic %>% group_by(ALV_ID) %>% select(mutation, freq.var, ALV_ID) -> clinic
merge(home, clinic, by = "mutation") %>% select(mutation, ALV_ID.x, SampleNumber, freq.var.x, ALV_ID.y, freq.var.y) -> home_vs_clinic

home_clinic_concordance <- ggplot(data = home_vs_clinic, aes(x=freq.var.x,y=freq.var.y)) + geom_point()+
  xlab("Frequency in home isolate") + ylab("Frequency in clinic isolate") + 
  geom_abline(slope=1,intercept = 0,lty=2)+
  scale_x_continuous(limits = c(0,0.5))+scale_y_continuous(limits = c(0,0.5)) + theme_bw()

# =========== Changes in frequency across paired home and clinic isolates ================ 

# Start with all variants from 2-50%, excluding the mixed infection.
variants_for_paired_sample_analysis <- isnv_minority_nomixed 

# Wrangle the metadata and variants.
meta_homeAndClinic <- filter(meta_short, home_spec == 1) # Take only those from which we have both home and clinic samples
meta_homeAndClinic <- mutate(meta_homeAndClinic, within_host_time = collect - home_spec_date)
variants_home <- filter(variants_for_paired_sample_analysis, ALV_ID %in% meta_homeAndClinic$home_spec_accn)
variants_clinic <- filter(variants_for_paired_sample_analysis, ALV_ID %in% meta_homeAndClinic$SPECID)
variants_home <- select(variants_home, ENROLLID, ALV_ID, freq.var, mutation, class_factor)
variants_clinic <- select(variants_clinic, ENROLLID, ALV_ID, freq.var, mutation, class_factor)
variants_home <- mutate(variants_home, mut_id = paste0(mutation, "_", ENROLLID))
variants_clinic <- mutate(variants_clinic, mut_id = paste0(mutation, "_", ENROLLID))
variants_home <- mutate(variants_home, mut_alv_id = paste0(mutation, "_", ALV_ID))
variants_clinic <- mutate(variants_clinic, mut_alv_id = paste0(mutation, "_", ALV_ID))
intra <- merge(variants_home, variants_clinic, by = "mut_id", all = TRUE)

# For those that are lost, we need to know if they became fixed. This info isn't in isnv_nomixed, which only includes 2-98%.
quality_var %>% mutate(mut_alv_id = paste0(mutation, "_", ALV_ID)) %>% filter(freq.var > 0.98) -> quality_var_fixed
intra <- mutate(intra, freq1 = ifelse(is.na(freq.var.x), quality_var_fixed$freq.var[match(mut_alv_id.x, quality_var_fixed$mut_alv_id)], freq.var.x)) # If freq in sample is NA, see if it's in quality_var_fixed. 
intra <- mutate(intra, freq2 = ifelse(is.na(freq.var.y), quality_var_fixed$freq.var[match(mut_alv_id.y, quality_var_fixed$mut_alv_id)], freq.var.y))
intra <- mutate(intra, freq1 = ifelse(is.na(freq.var.x), 0, freq.var.x)) # If the previous lines found nothing, then make them 0.
intra <- mutate(intra, freq2 = ifelse(is.na(freq.var.y), 0, freq.var.y))

# By enroll ID, give it the withinhost time from the metadata.
intra <- mutate(intra, ENROLLID = ifelse(!is.na(ENROLLID.x), ENROLLID.x, ENROLLID.y))
intra <- merge(intra, select(meta_homeAndClinic, ENROLLID, within_host_time), by = "ENROLLID")

# Define each mutation type.
intra %>% mutate(Endpoint = "Persistent") %>%
  mutate(Endpoint = if_else(freq1 == 0, "Arisen above 2%", Endpoint)) %>%
  mutate(Endpoint = if_else(freq2 == 0, "Lost below 2%", Endpoint)) -> intra
intra$Endpoint <- factor(intra$Endpoint, levels = c("Persistent", "Arisen above 2%", "Lost below 2%"), ordered = TRUE)
intra <- mutate(intra, class_factor = ifelse(is.na(class_factor.y), class_factor.x, class_factor.y))

# Make and save the plot.
intra.plot <- ggplot(intra, aes(x = as.factor(within_host_time),
                             y = freq2 - freq1,
                             fill = Endpoint)) +
  geom_quasirandom(pch=21, color = "black", size = 2) +
  scale_fill_manual(values = palette[c(1, 3, 5)], name = "") +
  xlab("Time within host (days)") + ylab("Change in frequency") + theme_bw() + facet_wrap(~class_factor)

#ggsave(plot = intra.plot, filename = "results/plots/IntraHostSNV_Longitudinal.jpg", device = "jpeg")
ggsave(plot = intra.plot, filename = "results/plots/IntraHostSNV_Longitudinal.pdf", device = "pdf", width = 5, height = 5)

# =========== SNVs in HA antigenic vs non-antigenic sites ================ 

# Not helpful since there are none in antigenic sites.

antigenic_sites <- read_csv("data/processed/antigenic_positions.csv")

VIC_start <- filter(antigenic_sites, Lineage == "B/VIC")$Start
VIC_end <- filter(antigenic_sites, Lineage == "B/VIC")$End
VIC_sites <- c()
for(r in 1:length(VIC_start))
{
  range <- c(VIC_start[r]:VIC_end[r])
  VIC_sites <- c(VIC_sites, range)
}

YAM_start <- filter(antigenic_sites, Lineage == "B/YAM")$Start
YAM_end <- filter(antigenic_sites, Lineage == "B/YAM")$End
YAM_sites <- c()
for(r in 1:length(YAM_start))
{
  range <- c(YAM_start[r]:YAM_end[r])
  YAM_sites <- c(YAM_sites, range)
}

variants_HA_nonsyn <- filter(isnv_minority_nomixed, class_factor == "Nonsynonymous" & chr == "HA") # only four! None in antigenic sites, by inspection.
variants_HA_nonsyn <- mutate(variants_HA_nonsyn, is_antigenic = ifelse(pcr_result == "B/VIC", pos %in% VIC_sites, pos %in% YAM_sites))

antigenic.plot <- ggplot(variants_HA_nonsyn, aes(y = freq.var, x = is_antigenic, color = class_factor)) +
  geom_quasirandom(varwidth = TRUE) +
  ylab("iSNV Frequency") + xlab(label = "") +
  scale_x_discrete(labels = c("Antigenic site","Nonantigenic site")) +
  scale_y_continuous(limits = c(0,1)) + scale_color_manual(name = "Mutation Class", values = palette[c(5,4)]) + ggtitle("Mutations in HA") + theme_bw()

