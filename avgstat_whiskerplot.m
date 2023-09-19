%
% create a matrix called data by copying and pasting from excel into
% command line
%
% then use the following code
%%%%%%%%%%%%%%%%%%%%%%%%
%% load data

NBACK_Corr = data1(:,1);
NBACK_Mean = data1(:,2);
NBACK_STD = data1(:,3);
NBACK_tSNR = data1(:,4);
NBACK_100_uV_Jumps = data1(:,5);
NBACK_200_uV_Jumps = data1(:,6);
NBACK_HFO = data1(:,7);

STIM_Corr = data2(:,1);
STIM_Mean = data2(:,2);
STIM_STD = data2(:,3);
STIM_tSNR = data2(:,4);
STIM_100_uV_Jumps = data2(:,5);
STIM_200_uV_Jumps = data2(:,6);
STIM_HFO = data2(:,7);

NBACK_Corr_Threshold = 0.5;
NBACK_Mean_Threshold = [-2 2];
NBACK_STD_Threshold = 70;
NBACK_tSNR_Threshold = 5;
NBACK_100_uV_Jumps_Threshold = 100;
NBACK_200_uV_Jumps_Threshold = 100;
NBACK_HFO_Threshold = 5;

STIM_Corr_Threshold = 0.5;
STIM_Mean_Threshold = [-5 5];
STIM_STD_Threshold = 100;
STIM_tSNR_Threshold = 10;
STIM_100_uV_Jumps_Threshold = 500;
STIM_200_uV_Jumps_Threshold = 500;
STIM_HFO_Threshold = 25;

%% plot data
figure
tiledlayout(1,14, 'TileSpacing', 'Loose')

nexttile
hold on
scatter(ones(length(NBACK_Corr),1), NBACK_Corr, 15,[0.7 0.7 0.7])
boxplot(NBACK_Corr, 'Colors', 'b', 'Symbol', 'b+')
yline(NBACK_Corr_Threshold, 'r')
hold off
title('NBACK Corr','Units', 'normalized', 'Position', [0.5, -0.1, 0], 'FontSize', 7)
ylabel("Pearson's Coefficient")
xticks([])
ylim([0 1])
nexttile
hold on
scatter(ones(length(STIM_Corr),1), STIM_Corr, 15,[0.7 0.7 0.7])
boxplot(STIM_Corr, 'Colors', 'g', 'Symbol', 'g+')
yline(STIM_Corr_Threshold, 'r')
hold off
title('STIM Corr','Units', 'normalized', 'Position', [0.5, -0.1, 0], 'FontSize', 7)
ylabel("Pearson's Coefficient")
xticks([])
ylim([0 1])

nexttile
hold on
scatter(ones(length(NBACK_Mean),1), NBACK_Mean, 15,[0.7 0.7 0.7])
boxplot(NBACK_Mean, 'Colors', 'b', 'Symbol', 'b+')
yline(NBACK_Mean_Threshold(1), 'r')
yline(NBACK_Mean_Threshold(2), 'r')
hold off
title('NBACK Mean','Units', 'normalized', 'Position', [0.5, -0.1, 0], 'FontSize', 7)
ylabel('Amplitude (\muV)')
xticks([])
ylim([-20 7.5])
nexttile
hold on
scatter(ones(length(STIM_Mean),1), STIM_Mean, 15,[0.7 0.7 0.7])
boxplot(STIM_Mean, 'Colors', 'g', 'Symbol', 'g+')
yline(STIM_Mean_Threshold(1), 'r')
yline(STIM_Mean_Threshold(2), 'r')
hold off
title('STIM Mean','Units', 'normalized', 'Position', [0.5, -0.1, 0], 'FontSize', 7)
ylabel('Amplitude (\muV)')
xticks([])
ylim([-20 7.5])

nexttile
hold on
scatter(ones(length(NBACK_STD),1), NBACK_STD, 15,[0.7 0.7 0.7])
boxplot(NBACK_STD, 'Colors', 'b', 'Symbol', 'b+')
yline(NBACK_STD_Threshold, 'r')
hold off
title('NBACK STD','Units', 'normalized', 'Position', [0.5, -0.1, 0], 'FontSize', 7)
ylabel('Amplitude (\muV)')
xticks([])
ylim([40 150])
nexttile
hold on
scatter(ones(length(STIM_STD),1), STIM_STD, 15,[0.7 0.7 0.7])
boxplot(STIM_STD, 'Colors', 'g', 'Symbol', 'g+')
yline(STIM_STD_Threshold, 'r')
hold off
title('STIM STD','Units', 'normalized', 'Position', [0.5, -0.1, 0], 'FontSize', 7)
ylabel('Amplitude (\muV)')
xticks([])
ylim([40 150])

nexttile
hold on
scatter(ones(length(NBACK_tSNR),1), NBACK_tSNR, 15,[0.7 0.7 0.7])
boxplot(NBACK_tSNR, 'Colors', 'b', 'Symbol', 'b+')
yline(NBACK_tSNR_Threshold, 'r')
hold off
title('NBACK tSNR','Units', 'normalized', 'Position', [0.5, -0.1, 0], 'FontSize', 7)
xticks([])
ylim([0 150])
nexttile
hold on
scatter(ones(length(STIM_tSNR),1), STIM_tSNR, 15,[0.7 0.7 0.7])
boxplot(STIM_tSNR, 'Colors', 'g', 'Symbol', 'g+')
yline(STIM_tSNR_Threshold, 'r')
hold off
title('STIM tSNR','Units', 'normalized', 'Position', [0.5, -0.1, 0], 'FontSize', 7)
xticks([])
ylim([0 150])

nexttile
hold on
scatter(ones(length(NBACK_100_uV_Jumps),1), NBACK_100_uV_Jumps, 15,[0.7 0.7 0.7])
boxplot(NBACK_100_uV_Jumps, 'Colors', 'b', 'Symbol', 'b+')
yline(NBACK_100_uV_Jumps_Threshold, 'r')
hold off
title('NBACK100uVJumps','Units', 'normalized', 'Position', [0.5, -0.1, 0], 'FontSize', 7)
ylabel('Count')
xticks([])
ylim([0 5000])
nexttile
hold on
scatter(ones(length(STIM_100_uV_Jumps),1), STIM_100_uV_Jumps, 15,[0.7 0.7 0.7])
boxplot(STIM_100_uV_Jumps, 'Colors', 'g', 'Symbol', 'g+')
yline(STIM_100_uV_Jumps_Threshold, 'r')
hold off
title('STIM100uVJumps','Units', 'normalized', 'Position', [0.5, -0.1, 0], 'FontSize', 7)
ylabel('Count')
xticks([])
ylim([0 5000])

nexttile
hold on
scatter(ones(length(NBACK_200_uV_Jumps),1), NBACK_200_uV_Jumps, 15,[0.7 0.7 0.7])
boxplot(NBACK_200_uV_Jumps, 'Colors', 'b', 'Symbol', 'b+')
yline(NBACK_200_uV_Jumps_Threshold, 'r')
hold off
title('NBACK200uVJumps','Units', 'normalized', 'Position', [0.5, -0.1, 0], 'FontSize', 7)
ylabel('Count')
xticks([])
ylim([0 3000])
nexttile
hold on
scatter(ones(length(STIM_200_uV_Jumps),1), STIM_200_uV_Jumps, 15,[0.7 0.7 0.7])
boxplot(STIM_200_uV_Jumps, 'Colors', 'g', 'Symbol', 'g+')
yline(STIM_200_uV_Jumps_Threshold, 'r')
hold off
title('STIM200uVJumps','Units', 'normalized', 'Position', [0.5, -0.1, 0], 'FontSize', 7)
ylabel('Count')
xticks([])
ylim([0 3000])

nexttile
hold on
scatter(ones(length(NBACK_HFO),1), NBACK_HFO, 15,[0.7 0.7 0.7])
boxplot(NBACK_HFO, 'Colors', 'b', 'Symbol', 'b+')
yline(NBACK_HFO_Threshold, 'r')
hold off
title('NBACK HFO','Units', 'normalized', 'Position', [0.5, -0.1, 0], 'FontSize', 7)
ylabel('Count')
xticks([])
ylim([0 30])
nexttile
hold on
scatter(ones(length(STIM_HFO),1), STIM_HFO, 15,[0.7 0.7 0.7])
boxplot(STIM_HFO, 'Colors', 'g', 'Symbol', 'g+')
yline(STIM_HFO_Threshold, 'r')
hold off
title('STIM HFO','Units', 'normalized', 'Position', [0.5, -0.1, 0], 'FontSize', 7)
ylabel('Count')
xticks([])
ylim([0 30])
sgtitle('Raw Data Metrics - NU Data - All Channel Averages')






