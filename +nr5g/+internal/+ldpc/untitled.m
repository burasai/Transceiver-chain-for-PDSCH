  bgn = 2;               % Base graph number
  K = 2560;              % Code block segment length
  F = 36;                % Number of filler bits per code block segment
  C = 2;                 % Number of code blocks
  cbs = ones(K-F,C);  
  fillers = -1*ones(F,C);
  cbs = [cbs;fillers];   % Code block segments with filler bits
  codedcbs = nrLDPCEncode(cbs,bgn);
  size(codedcbs)