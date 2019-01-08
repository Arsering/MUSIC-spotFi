%% 本函数可以得到在不同的信噪比值之下 对于特定的路径数量 AOA和TOF的误差分布
%% 设定参数
num_path = 1; % 路径个数
num_AP = 3; % 共有多少个AP
AOA_or_TOF = 2;% 等于1表示求AOA的错误率，等于2表示求TOF的错误率
num_experiment = 500; % 每个SNR下实验次数
has_noise = 1; % 为1则添加噪声 否则不添加噪声
SNR_vector = [50,30,20,10,0]; % 测试的SNR范围
error = zeros(length(SNR_vector),num_experiment); % 存储错误个数
mark = {'r-+' 'g--o' 'b*:' 'c-.s' 'm-p' 'b--h'}; % 不同折线图具有不同的颜色、线型、点标记

%% 得到误差值
for m = 1:length(SNR_vector)
    for t = 1:num_experiment
        AP_index = mod(t,num_AP) + 1; % AP的索引
        [path_info_input,path_info_output] = simulation_environment(num_path,SNR_vector(m),AP_index,has_noise);

        %找最短路径对应的下标
        minTOF_index = 1;
        for k = 2:size(path_info_output,1)
            if path_info_output(k,2) < path_info_output(minTOF_index,2)
                minTOF_index = k;
            end
        end

        error(m,t) = abs(path_info_output(minTOF_index,AOA_or_TOF) - path_info_input(1,AOA_or_TOF)); % 
        
    end
end


%% 生成图表
    
%求得AOA的误差的上下限
format longE
max_error = max(max(error));
min_error = 0;

x_vector = linspace(min_error,max_error,15);
y_vector = zeros(length(SNR_vector),length(x_vector));

%求error的分布
for m = 1:length(SNR_vector)
    for t = 2:length(x_vector)
        for k = 1:length(error(m,:))
            if error(m,k) <= x_vector(t)
                y_vector(m,t) =  y_vector(m,t) + 1;
            end
        end
    end
end


y_vector = y_vector ./ num_experiment;
figure;
hold on;
for m = 1:length(SNR_vector)
    sign = [' SNR ',num2str(SNR_vector(m)),'dB'];
    plot(x_vector,y_vector(m,:),mark{m},'DisplayName',sign,'LineWidth',0.75);
end
legend();
if AOA_or_TOF == 1
    xlab = 'AOA';
else
    xlab = 'TOF';
end
xlabel([xlab,' error']);  %x轴坐标描述
ylabel('CDF'); %y轴坐标描述
hold off;

