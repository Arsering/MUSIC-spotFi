function [path_info_output]=my_music(CSI,WLAN_paras,signal_space)
%%  chanEst 信道估计值 Nsb-Ntx-Nrx
%    numSC    被使用的子载波的数量
%    numTX    被使用的天线的数量
%    signal_space 标量时表示对应于信号空间的特征值的个数
%                 向量时第一个元素表示对应于信号空间的特征值的最大值，第二个元素表示对应于信号空间的特征值的下界
%    per_frequency 相邻子载波之间的频率差 置为 312.5Hz
%     d 接收天线之间的距离=波长*d

row = floor(WLAN_paras.num_subcarrier/2) * 2;% smoothed_CSI的行数
column=(WLAN_paras.num_subcarrier - row/2 + 1) * (WLAN_paras.num_antenna - 1);% smoothed_CSI的列数

%定义smoothed_CSI的存储矩阵
smoothed_CSI = zeros(row,column,'like',CSI);


%构造smoothed_CSI
for k = 1:(WLAN_paras.num_antenna-1)
    for t = 1:(WLAN_paras.num_subcarrier - row/2 + 1)
        smoothed_CSI(:,t + (k-1)*(WLAN_paras.num_subcarrier - row/2 + 1)) = [CSI(k,t:(t+row/2-1)),CSI(k+1,t:(t+row/2-1))].';
    end
end

% 计算smoothed_CSI的特征值及其对应的特征向量
correlation_matrix = smoothed_CSI * smoothed_CSI';
[E,D] = eig(correlation_matrix);

 % 找到noise_space对应的特征向量
[~,indx] = sort(diag(D),'descend');
eigenvects = E(:,indx);
noise_eigenvects = eigenvects(:,(signal_space+1):end);

antenna_space = (WLAN_paras.speed_light/WLAN_paras.frequency) * WLAN_paras.antenna_space_ofwaveLen; % 相邻天线之间距离 单位：m

%确定采样点
X = 0:1:180;
Y = ((10^-7)/40):((10^-7)/40):10^-7;
% [sample_AoA,sample_ToF] = meshgrid(X,Y);
samples = complex(zeros(length(X),length(Y)));

%采样
for t = 1:length(X)
    for k = 1:length(Y)
       
        angleE = exp(-1i * 2 * pi * antenna_space * cos(X(t)*pi/180) * WLAN_paras.frequency / WLAN_paras.speed_light);
        timeE = exp(-1i * 2 * pi * WLAN_paras.frequency_space * Y(k));
        steering_vector = complex(zeros(row,1));
        for n=0:1
            for m=1:row/2
                steering_vector((n*row/2)+m,1) = angleE.^n * timeE.^(m-1);
            end
        end
        samples(t,k) = 1/sum(abs(noise_eigenvects' * steering_vector).^2,1);
    end
end

%% 生成三维图像
mesh(Y,X,samples);
xlabel('X(TOF/s)');
ylabel('Y(AOA/°)');
% surf(sample_AoA,sample_ToF,samples.')
shading interp;

%% 
%定义存储求得的AOA TOF的矩阵
path_info_output = zeros(signal_space,2);
max_N_value = zeros(1,signal_space);

%寻找前signal_space个极大值点
for m = 1:length(X)
    for n = 1:length(Y)
        step = [1 0;0 1;-1 0;0 -1];
        scope = [length(X),length(Y)];
        mark = 1;

        %判断当前点是否为极大值点
        for k = 1:size(step,1)
            temp_x = m + step(k,1);
            if temp_x < 1 || temp_x > scope(1)
                temp_x = m;
            end
            temp_y = n + step(k,2);
            if temp_y < 1 ||temp_y > scope(2)
                temp_y = n;
            end
            if samples(m,n) < samples(temp_x,temp_y)
                mark = 0;
                break;
            end
        end
       
        %如果为极大值点，则存储起来
        if mark == 1
            min_index = minI(max_N_value);
            if max_N_value(min_index) < samples(m,n)
                max_N_value(min_index) =  samples(m,n);
                path_info_output(min_index,:) = [X(m) Y(n)];
            end
        end
    end
end

end


%% 求得输入数组中最小元素的下标

function index = minI(input)
    index  = 1;
    for k = 2:length(input)
        if input(k) < input(index)
            index = k;
        end
    end
end

