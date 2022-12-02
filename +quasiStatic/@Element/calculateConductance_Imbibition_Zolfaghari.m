function calculateConductance_Imbibition_Zolfaghari(element, network, Pc)
Pc = abs(Pc);

if ~any(element.oilLayerExist)
    
    if element.occupancy == 'B'
        if strcmp(element.geometry , 'Circle')== 1
            
            element.waterCrossSectionArea = 0;
            element.waterConductance = 0;
            element.oilCrossSectionArea = element.area;
            element.oilConductance = element.conductanceSinglePhase;
            element.waterSaturation = 0;
            element.oilSaturation = 1;
        else
            halfAngles = [element.halfAngle1, element.halfAngle2,element.halfAngle3, element.halfAngle4];
            cornerArea = zeros(1,4);    cornerConductance = zeros(1,4); 
            
            for i = 1:4
                if ~isnan(halfAngles(i)) && ~isnan(element.waterCornerExist(i))
                    %Raduis of Curvature
                    rso1 = element.sig_ow / Pc;
                    rpd = element.sig_ow / network.Pc_drain_max;
                    part = rpd * cos(element.recedingContactAngle+halfAngles(i))/rso1;
                    element.hingeAngles(i) = acos(part) - halfAngles(i);
                    element.hingeAngles(i) = min (element.hingeAngles(i), element.advancingContactAngle);
                    element.b(i) = rso1 * cos(element.hingeAngles(i) + halfAngles(i))/sin(halfAngles(i));
                    % Area
                    cornerArea(i) = rso1^2 * (element.hingeAngles(i) + halfAngles(i) - pi/2 ...
                        +  cos(element.hingeAngles(i)) * cos(element.hingeAngles(i) + halfAngles(i))/ sin (halfAngles(i)));
                    %Conductance
                    % Based on Piri_2005: eq B(10 - 15)
                    f = 1; % no-flow boundary condition suitable for oil-water interfaces
                    F1 = pi/2 - halfAngles(i) - element.hingeAngles(i);
                    F2 = cot(halfAngles(i)) * cos(element.hingeAngles(i)) - sin(element.hingeAngles(i));
                    F3 = (pi/2 - halfAngles(i)) * tan(halfAngles(i));
                    
                    if (element.hingeAngles(i) <= pi/2 - halfAngles(i))  % Positive Curvature
                        cornerConductance(i) = (cornerArea(i)^2 * (1 - sin(halfAngles(i)))^2 * ...
                            (F2 * cos(element.hingeAngles(i)) - F1) * F3 ^ 2) / ...
                            (12 * element.waterViscosity * ((sin(halfAngles(i))) * ...
                            (1 - F3) * (F2 + f * F1))^ 2);
                    elseif (element.hingeAngles(i) > pi/2 - halfAngles(i)) % Negative Curvature
                        cornerConductance(i) = (cornerArea(i)^2 * tan(halfAngles(i))* ...
                            (1 - sin(halfAngles(i)))^2 * F3 ^ 2) / ...
                            (12 * element.waterViscosity *(sin(halfAngles(i)))^2*(1 - F3) * (1 + f * F3)^ 2);
                    end
                end
                
                element.waterCrossSectionArea = sum(cornerArea);
                element.waterConductance = sum(cornerConductance);
            end
            element.oilCrossSectionArea = element.area - element.waterCrossSectionArea;
            if strcmp(element.geometry , 'Triangle')== 1
                element.oilConductance = element.oilCrossSectionArea^2 * 3  * element.shapeFactor / element.oilViscosity/5;
            elseif strcmp(element.geometry , 'Square')== 1
                element.oilConductance = element.oilCrossSectionArea^2 *0.5623 * element.shapeFactor /element.oilViscosity;
            end
            element.waterSaturation = element.waterCrossSectionArea/element.area;
            element.oilSaturation = element.oilCrossSectionArea/element.area;
        end
    else
        element.waterCrossSectionArea = element.area;
        element.waterConductance = element.conductanceSinglePhase;
        element.oilCrossSectionArea = 0;
        element.oilConductance = 0;
        element.waterSaturation = 1;
        element.oilSaturation = 0;
    end
    
else
    if strcmp(element.geometry , 'Triangle')== 1
        nc = 3;
    else
        nc = 4;
    end
    
    R = network.sig_ow / Pc; %Raduis of Curvature
    halfAngles = [element.halfAngle1, element.halfAngle2,element.halfAngle3, element.halfAngle4];
    inerArea = zeros(1,nc);
    outerArea = zeros(1,nc);
    layerArea = zeros(1,nc);
    inerConductance = zeros(1,nc);
    layerConductance = zeros(1,nc);
    for jj = 1:nc
        if ~isnan(element.oilLayerExist(1,jj)) %if the layer exist in the corner
            
            R_min = network.sig_ow / network.Pc_drain_max;
            part = R_min * cos(element.recedingContactAngle+halfAngles(jj))/R;
            if part > 1
                part = 1;
            elseif part < -1
                part = -1;
            end
            thetaHingRec = acos( part)-halfAngles(jj);
            thetaHingRec = min(thetaHingRec, element.advancingContactAngle);
            
            % Area of corner water
            if (halfAngles(jj) + thetaHingRec) == pi/2
                inerArea(jj) = (R * cos(thetaHingRec + halfAngles(jj))/ sin (halfAngles(jj)))^2 *...
                    sin(halfAngles(jj)) * cos(halfAngles(jj));
            else
                inerArea(jj) = R ^2 * (cos(thetaHingRec)*...
                    (cot(halfAngles(jj)) * cos(thetaHingRec) - sin(thetaHingRec))+ ...
                    thetaHingRec+ halfAngles(jj) - pi/2);
            end
            
            f = 1; % no-flow boundary condition suitable for oil-water interfaces
            F1 = pi/2 - halfAngles(jj) - thetaHingRec;
            F2 = cot(halfAngles(jj)) * cos(thetaHingRec) - sin(thetaHingRec);
            F3 = (pi/2 - halfAngles(jj)) * tan(halfAngles(jj));
            
            % Conductance of corner water
            if thetaHingRec <= pi/2 - halfAngles(jj) % Positive Curvature
                
                inerConductance(jj) = (inerArea(jj)^2 * (1 - sin(halfAngles(jj)))^2 * ...
                    (F2 * cos(thetaHingRec) - F1) * F3 ^ 2) / ...
                    (12 * network.waterViscosity * ((sin(halfAngles(jj))) * ...
                    (1 - F3) * (F2 + f * F1))^ 2);
            elseif (thetaHingRec > pi/2 - halfAngles(jj)) % Negative Curvature
                inerConductance(jj) = (inerArea(jj)^2 * tan(halfAngles(jj))* ...
                    (1 - sin(halfAngles(jj)))^2 * F3 ^ 2) / ...
                    (12 * network.waterViscosity *(sin(halfAngles(jj)))^2*(1 - F3) * (1 + f * F3)^ 2);
            end
            
            thetaHingAdv = pi - element.advancingContactAngle;
            if (halfAngles(jj) + thetaHingAdv) == pi/2
                outerArea(jj) = (R * cos(thetaHingAdv + halfAngles(jj))/ sin (halfAngles(jj)))^2 *...
                    sin(halfAngles(jj)) * cos(halfAngles(jj));
            else
                outerArea(jj) = R ^2 * (cos(thetaHingAdv)*...
                    (cot(halfAngles(jj)) * cos(thetaHingAdv) - sin(thetaHingAdv))+ ...
                    thetaHingAdv+ halfAngles(jj) - pi/2);
            end
            % Area of oil layer
            layerArea(jj) = outerArea(jj)-inerArea(jj);
            % Conductance of oil layer
            F3_layer = (pi/2 - halfAngles(jj)) * tan(halfAngles(jj));
            layerConductance(jj) = (layerArea(jj)^3 * (1 - sin(halfAngles(jj)))^2 * ...
                tan(halfAngles(jj)) * F3_layer ^ 2) / ...
                (12 * network.oilViscosity *outerArea(jj)* (sin(halfAngles(jj)))^2 * ...
                (1 - F3_layer) * (1 + F3_layer - (1- F3) * sqrt(inerArea(jj)/outerArea(jj))));
        end
    end
    % Center water area and conductance
    centerWaterArea = element.area - sum(outerArea);
    if strcmp(element.geometry , 'Triangle')== 1
        centerWaterConductance = 3 *element.radius^2*centerWaterArea/20/network.waterViscosity;
    else
        centerWaterConductance = 0.5623 * element.shapeFactor * centerWaterArea^2/network.waterViscosity;
    end
    
    element.waterCrossSectionArea = element.area - sum(layerArea);
    element.waterConductance = centerWaterConductance + sum(inerConductance);
    element.oilCrossSectionArea = sum(layerArea);
    element.oilConductance = sum(layerConductance);
    element.waterSaturation = element.waterCrossSectionArea/element.area;
    element.oilSaturation = element.oilCrossSectionArea/element.area;
end
if element.waterSaturation > 1
    % Control
    fprintf('sat %f %4.0d  %f \n',Pc, element.index,element.waterSaturation);
    element.control(1:3) = [Pc, element.imbThresholdPressure_PistonLike, element.imbThresholdPressure_SnapOff];
    
    element.waterCrossSectionArea = element.area;
    element.waterConductance = element.conductanceSinglePhase;
    element.oilCrossSectionArea = 0;
    element.oilConductance = 0;
    element.waterSaturation = 1;
    element.oilSaturation = 0;
end
end