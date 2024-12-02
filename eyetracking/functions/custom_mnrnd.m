function output = custom_mnrnd(probabilities)
    % Check if probabilities sum to 1
    if abs(sum(probabilities) - 1) > 1e-10
        error('Probabilities must sum to 1');
    end
    
    % Cumulative sum of probabilities
    cumulative_p = cumsum(probabilities);
    
    % Generate a random number between 0 and 1
    r = rand;
    
    % Find the category based on the cumulative probability
    category = find(r <= cumulative_p, 1);
    
    % Create an output in the form of a one-hot vector
    output = zeros(1, length(probabilities));
    output(category) = 1;
end

