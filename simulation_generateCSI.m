function [CSI,path_info] = simulation_generateCSI(WLAN_paras,AP_index)
% target_location 是定位目标的位置 大小为：1-2（一般设置为坐标原点）
% AP_location 是AP的位置 大小为：2-2 每个AP对应着两行且 
%              每行表示一个二维坐标点，两个坐标点即确定了一个AP中所有天线所在的
%              平面。默认两个坐标点中距离target最近的即为天线组中第一个天线的位
%              置，另一个坐标点代表天线组中的其他成员与第一个天线的位置关系
% frequency 信息传输的工作频率 单位：Hz
% antenna_space AP上相邻天线之间的距离 表示为波长的倍数
% num_antenna 每个AP上天线的个数
% num_subcarrier 每个天线上的子载波数
% 
% 返回值：CSI Nantenna-Nsubcarrier
%         path_info Npath-2


% 获得距离target最近的点的行号
[~,min_index] = min(sum((WLAN_paras.target_location - WLAN_paras.APs_location(:,:,AP_index)).^2,2));

if min_index == 1
    max_index = 2;
else
    max_index = 1;
end


%定义存储路径信息的矩阵 每行第一个是ToF 第二个是AoA 范围：（0，180）
path_info = zeros(WLAN_paras.num_path,2);

% 直接路径对应的AoA ToF
signal_vector = WLAN_paras.APs_location(min_index,:,AP_index) - WLAN_paras.target_location; % 直接路径对应的向量
antenna_vector = WLAN_paras.APs_location(max_index,:,AP_index) - WLAN_paras.APs_location(min_index,:,AP_index); % 天线组所在直线对应的向量
path_info(1,2) = sqrt(sum(signal_vector.^2,2)) / WLAN_paras.speed_light;
path_info(1,1) = acos(signal_vector * antenna_vector.'/(sqrt(sum(signal_vector.^2,2) * sum(antenna_vector.^2,2))))*180/pi;
    
% 随机产生两条非直接路径的AoA ToF
for k = 2:WLAN_paras.num_path
    path_info(k,2) = (rand + WLAN_paras.add_len) * path_info(1,2);
    path_info(k,1) = rand * 180;
end

% 相邻天线之间距离 单位：m
antenna_space = (WLAN_paras.speed_light/WLAN_paras.frequency) * WLAN_paras.antenna_space_ofwaveLen;

% 定义存储CSI值的矩阵
CSI = complex(zeros(WLAN_paras.num_antenna,WLAN_paras.num_subcarrier));

%计算CSI
for k = 1:size(path_info,1)
    exp_AoA = exp((2 * pi * antenna_space * cos(path_info(k,1)*pi / 180) * WLAN_paras.frequency / WLAN_paras.speed_light) * -1i);
    exp_ToF = exp(2 * pi * WLAN_paras.frequency_space * path_info(k,2) * -1i);
    
    for t = 1:WLAN_paras.num_antenna
        tmp_AoA = exp_AoA.^(t-1);
        for m = 1:WLAN_paras.num_subcarrier
            CSI(t,m) = CSI(t,m) + exp_ToF.^(m - 1) * tmp_AoA * WLAN_paras.path_complex_gain(AP_index,k); 
        end
    end
end

if WLAN_paras.has_noise == 1
    CSI = awgn(CSI,WLAN_paras.SNR,'measured');
end



% 
% awgnChannel = comm.AWGNChannel;
% awgnChannel.NoiseMethod = 'Signal to noise ratio (SNR)';
% % Normalization
% awgnChannel.SignalPower =1/sum(WLAN_paras.path_complex_gain(AP_index));
% % Account for energy in nulls
% awgnChannel.SNR = WLAN_paras.SNR;
% CSI = awgnChannel(CSI);


% %产生噪声矩阵
% noise = wgn(WLAN_paras.num_antenna,1,WLAN_paras.SNR,'complex');
% 
% %给CSI值添加噪声
% for t = 1:WLAN_paras.num_antenna
%     for m = 1:WLAN_paras.num_subcarrier
%         CSI(t,m) = CSI(t,m) + noise(t); 
%     end
% end


end

