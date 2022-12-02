function networkInfoPlots(network, Plots)

if strcmp(Plots , 'True')== 1
    %% Plot Pore & Throat size distribution
    figure('name','Pore Size Distribution')
    title('Pore Size Distribution')
    hist(network.PSD);
    title('Pore Size Distribution')
    xlabel('Pore radius (m)') 
    ylabel('Frequency')
    hold on
    figure('name','Throat Size Distribution')
    hist(network.ThSD);
    title('Throat Size Distribution')
    xlabel('Throat radius (m)') 
    ylabel('Frequency')
    hold on
    
    % Plot Pressure
    figure('name','Pressure Distribution')
    % a , b are 2 surfaces perpendicular to x-direction with
    % distance equals to intervalx
    
    x_coor = zeros(network.numberOfNodes,1);
    for ii = 1:network.numberOfNodes
        x_coor(ii,1) = network.Nodes{ii}.x_coordinate;
    end
    x_outlet = max(x_coor);
    x_inlet = min(x_coor);
    n = 100;
    intervalx = (x_outlet - x_inlet)/n;
    a = x_inlet;
    b = x_inlet + intervalx;
    x = zeros(n,1);
    press_x = zeros(100,1);
    for i = 1:n
        area = 0;
        for ii = 1:network.numberOfNodes
            if network.Nodes{ii}.x_coordinate >= a && network.Nodes{ii}.x_coordinate < b
                %                        press_x(i) = press_x(i) + network.Nodes{ii}.waterPressure*network.Nodes{ii}.area;
                %                        area= area+obj.Nodes{ii}.area;
                press_x(i) = press_x(i) + network.Nodes{ii}.waterPressure;
                area= area+1;
            end
        end
        for ii = 1:network.numberOfLinks
            if ~network.Links{ii}.isOutlet
                if network.Nodes{network.Links{ii}.pore2Index}.x_coordinate >= a && network.Nodes{network.Links{ii}.pore2Index}.x_coordinate < b
                    % press_x(i) = press_x(i) + obj.Links{ii}.waterPressure*obj.Links{ii}.area;
                    % area= area+obj.Links{ii}.area;
                    press_x(i) = press_x(i) + network.Links{ii}.waterPressure;
                    area = area + 1;
                end
            end
        end
        press_x(i)=press_x(i)/area;
        x(i) = x(i) + i*intervalx;
        a = a + intervalx;
        b = b + intervalx;
    end
    plot(x, press_x, '*')
    title('Pressure drop in x-direction')
    xlabel('X(m)')
    xlim([x_inlet x_outlet])
    ylabel('Pressure(Pa)')
end