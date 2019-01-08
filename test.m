% [path_info_input,path_info_output] = simulation_environment(1,50,2);
% format longE
% path_info_input
% path_info_output
% % 
% % noise = wgn(1000,1,0);
% mean(noise)





num_path = 1;
num_experiment = 1;
SNR_vector = [20];
error = zeros(length(SNR_vector),num_experiment);
mark = {'r-+' 'g--o' 'b*:' 'c-.s' 'm-p' 'y--h'};

for m = 1:length(SNR_vector)
    for t = 1:num_experiment
        [path_info_input,path_info_output] = simulation_environment(1,SNR_vector(m),3);

        %找最短路径对应的下标
        minTOF_index = 1;
        AP_index = 1;
        for k = 2:size(path_info_output,1)
            if path_info_output(k,2) < path_info_output(minTOF_index,2)
                minTOF_index = k;
            end
        end
        format longE
        path_info_output(:,:);
        error(m,t) = abs(path_info_output(minTOF_index,2) - path_info_input(1,2));
    end
end
    
%求得AOA的误差的上下限
format longE
max_error = max(max(error));
min_error = 0;

x_vector = linspace(min_error,max_error,11);
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

% 
% y_vector = y_vector ./ num_experiment;
% figure;
% hold on;
% for m = 1:length(SNR_vector)
%     sign = [' SNR ',num2str(SNR_vector(m)),'dB'];
%     plot(x_vector,y_vector(m,:),mark{m},'DisplayName',sign,'LineWidth',0.75);
% end
% legend();
% xlabel('error');  %x轴坐标描述
% ylabel('CDF'); %y轴坐标描述
% hold off;

