function KF = UpdateCursor(Params,Neuro,TaskFlag,TargetPos,KF)
% UpdateCursor(Params,Neuro)
% Updates the state of the cursor using the method in Params.ControlMode
%   1 - position control
%   2 - velocity control
%   3 - kalman filter  velocity
%
% Cursor - global structure with state of cursor [px,py,vx,vy,1]
% TaskFlag - 0-imagined mvmts, 1-clda, 2-fixed decoder
% TargetPos - x- and y- coordinates of target position. used to assist
%   cursor to target
% KF - kalman filter struct containing matrices A,W,P,C,Q

global Cursor

% query optimal control policy
Vopt = OptimalCursorUpdate(Params,TargetPos);

if TaskFlag==1, % do nothing during imagined movements
    return;
end

% find vx and vy using control scheme
switch Cursor.ControlMode,
    case 1, % Move to Mouse
        [x,y] = GetMouse();
        vx = ((x-Params.Center(1)) - Cursor.State(1))*Params.UpdateRate;
        vy = ((y-Params.Center(2)) - Cursor.State(2))*Params.UpdateRate;
        
        % update cursor
        Cursor.State(1) = x - Params.Center(1);
        Cursor.State(2) = y - Params.Center(2);
        Cursor.State(3) = vx;
        Cursor.State(4) = vy;
        
        % Update Intended Cursor State
        Cursor.IntendedState = Cursor.State; % current true position
        Cursor.IntendedState(3:4) = Vopt; % update vel w/ optimal vel
        
    case 2, % Use Mouse Position as a Velocity Input (Center-Joystick)
        [x,y] = GetMouse();
        vx = Params.Gain * (x - Params.Center(1));
        vy = Params.Gain * (y - Params.Center(2));
        
        % assisted velocity
        if Cursor.Assistance > 0,
            Vcom = [vx;vy];
            Vass = Cursor.Assistance*Vopt + (1-Cursor.Assistance)*Vcom;
        else,
            Vass = [vx;vy];
        end
        
        % update cursor state
        Cursor.State(1) = Cursor.State(1) + Vass(1)/Params.UpdateRate;
        Cursor.State(2) = Cursor.State(2) + Vass(2)/Params.UpdateRate;
        Cursor.State(3) = Vass(1);
        Cursor.State(4) = Vass(2);
        
        % Update Intended Cursor State
        Cursor.IntendedState = Cursor.State; % current true position
        Cursor.IntendedState(3:4) = Vopt; % update vel w/ optimal vel
        
    case 3, % Kalman Filter Velocity Input
        X0 = Cursor.State; % initial state, useful for assistance
        
        % Kalman Predict Step
        X = X0;
        if Neuro.DimRed.Flag,
            Y = Neuro.NeuralFactors;
        else,
            Y = Neuro.NeuralFeatures;
        end
        A = KF.A;
        W = KF.W;
        P = KF.P;
        X = A*X;
        P = A*P*A' + W;
        
        % Kalman Update Step
        C = KF.C;
        if KF.CLDA.Type==3 && TaskFlag==2,
            Q = KF.Q; % faster since avoids updating Qinv online
            K = P*C'/(C*P*C' + Q);
        else, % faster once Qinv is computed (fixed decoder or refit/batch)
            Qinv = KF.Qinv;
            K = P*C'*Qinv*(eye(size(Y,1)) - C/(inv(P) + C'*Qinv*C)*(C'*Qinv)); % RML Kalman Gain eq (~8ms)
        end
        X = X + K*(Y - C*X);
        P = P - K*C*P;
        
        % Store Params
        Cursor.State = X;
        KF.P = P;
        
        % assisted velocity
        if Cursor.Assistance > 0,
            Vcom = (X(1:2) - X0(1:2))*Params.UpdateRate; % effective velocity command
            Vass = Cursor.Assistance*Vopt + (1-Cursor.Assistance)*Vcom;
            if norm(Vass)>200, % fast
                Vass = 200 * Vass / norm(Vass);
            end
            
            % update cursor state
            Cursor.State(1) = X0(1) + Vass(1)/Params.UpdateRate;
            Cursor.State(2) = X0(2) + Vass(2)/Params.UpdateRate;
            Cursor.State(3) = Vass(1);
            Cursor.State(4) = Vass(2);
        end
        
        % Update KF Params (RML & Adaptation Block)
        if KF.CLDA.Type==3 && TaskFlag==2,
            % use intended state for param update
            Cursor.IntendedState = Cursor.State; % current true position
            Cursor.IntendedState(3:4) = Vopt; % update vel w/ optimal vel
            KF = UpdateRmlKF(KF,Cursor.IntendedState,Y);
        end
        
end


% bound cursor position to size of screen
pos = Cursor.State(1:2)' + Params.Center;
pos(1) = max([pos(1),Params.ScreenRectangle(1)+10]); % x-left
pos(1) = min([pos(1),Params.ScreenRectangle(3)-10]); % x-right
pos(2) = max([pos(2),Params.ScreenRectangle(2)+10]); % y-left
pos(2) = min([pos(2),Params.ScreenRectangle(4)-10]); % y-right
Cursor.State(1) = pos(1) - Params.Center(1);
Cursor.State(2) = pos(2) - Params.Center(2);

end % UpdateCursor