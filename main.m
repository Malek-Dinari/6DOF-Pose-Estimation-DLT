% Charger les données et l'image
load('./data/3D2Dpoints.mat');  % Charger les points 3D et 2D
img = imread('data/cubeRGB.JPG'); % Charger l'image RGB

% Convertir les cellules en tableaux numériques si nécessaire
if iscell(x)
    x = x{1, 1}; % Extraire les données de la cellule
end
if iscell(X)
    X = X{1, 1}; % Extraire les données de la cellule
end

% Étape 1 : Visualisation des points 2D sur l'image RGB
figure;
imshow(img); 
hold on;

% Afficher les points 2D sur l'image
keypoints_2d = x;  % Points 2D (x, y)
plot(keypoints_2d(1,:), keypoints_2d(2,:), 'ro', 'MarkerFaceColor', 'b');

% Ajouter des titres et labels
title("Points 2D sur l'image RGB");
xlabel('X');
ylabel('Y');
hold off;

% Étape 2 : Visualisation des points 3D et des arêtes du cube
figure;
hold on;

% Afficher les points 3D
scatter3(Xmodel(1,:), Xmodel(2,:), Xmodel(3,:), 'r', 'filled');

% Tracer les arêtes du cube
for i = 1:length(startind)
    start_point = Xmodel(:, startind(i));
    end_point = Xmodel(:, endind(i));
    plot3([start_point(1), end_point(1)], ...
          [start_point(2), end_point(2)], ...
          [start_point(3), end_point(3)], 'k-', 'LineWidth', 1);
end

% Ajouter des titres et labels
xlabel('X');
ylabel('Y');
zlabel('Z');
title('Points 3D et arêtes du cube');
axis equal;
grid on;
view(3); % Vue 3D
rotate3d on; % Rotation interactive
hold off;

% Étape 3 : Calcul de la matrice de projection P avec DLT
n = size(X, 2); % Nombre de correspondances
M = zeros(2 * n, 12); % Initialisation de la matrice M

% Construction de la matrice M
for i = 1:n
    X_i = X(:, i)'; % Point 3D (homogène)
    x_i = x(:, i);  % Point 2D correspondant
    M(2 * i - 1, :) = [X_i, 1, zeros(1, 4), -x_i(1) * [X_i, 1]];
    M(2 * i, :)     = [zeros(1, 4), X_i, 1, -x_i(2) * [X_i, 1]];
end

% Résolution du système linéaire avec SVD
[~, ~, V] = svd(M);
v = V(:, end); % Dernière colonne de V (solution)
P = reshape(v, 4, 3)'; % Redimensionner en matrice 3x4

% Étape 4 : Reprojection des points 3D pour validation
X_h = [X; ones(1, n)]; % Coordonnées homogènes des points 3D
x_proj = P * X_h; % Reprojection
x_proj = x_proj ./ x_proj(3, :); % Normalisation

% Affichage des points originaux et reprojetés
figure;
imshow(img); 
hold on;
scatter(x(1, :), x(2, :), 'r', 'filled'); % Points originaux
scatter(x_proj(1, :), x_proj(2, :), 'g', 'filled'); % Points reprojetés
title('Points originaux (rouge) vs reprojetés (vert)');
hold off;

% Calcul de l'erreur quadratique moyenne (MSE)
mse = mean(sum((x(1:2, :) - x_proj(1:2, :)).^2, 1));
fprintf('Erreur quadratique moyenne (MSE) : %.4f\n', mse);

% Étape 5 : Détermination de la pose (K, R, t)
M = P(:, 1:3); % Extraction de la sous-matrice M
sign_det_M = sign(det(M)); % Signe du déterminant de M
P = P * sign_det_M; % Normalisation de P

% Calcul du centre de la caméra C avec SVD
[~, ~, V] = svd(P);
C = V(1:3, end) / V(end, end); % Centre de la caméra

%load('data\rq.m') : Doesn't work, needs to be a mat file
% Add the data directory to the MATLAB path
addpath('C:\Users\Lenovo\Desktop\programming\TASKS-and-PROJECTS-2024-25\Mme-Enjie-PnP\data');


% Factorisation RQ pour obtenir K et R
[R, K] = rq(M); % Utilisation de la fonction rq fournie

% Calcul du vecteur de translation t
t = -R * C;

% Affichage des résultats
disp('Matrice intrinsèque K :');
disp(K);
disp('Paramètres extrinsèques: [R, t]');
disp('Matrice de rotation R :');
disp(R);
disp('Vecteur de translation t :');
disp(t);