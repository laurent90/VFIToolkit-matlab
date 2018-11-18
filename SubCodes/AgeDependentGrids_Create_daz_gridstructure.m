function daz_gridstructure=AgeDependentGrids_Create_daz_gridstructure(n_d,n_a,n_z,N_j,d_gridfn, a_gridfn, z_gridfn, AgeDependentGridParamNames, options)
% Creates daz_gridstructure which contains both the grids themselves and a
% bunch of info about the grids in an easy to access way.
% e.g., the d_grid for age j=10: daz_gridstructure.d_grid.j010
% e.g., the value of N_a for age j=5: daz_gridstructure.N_a.j005
% e.g., the zprime_grid for age j=20: daz_gridstructure.zprime_grid.j020


% Create a structure that contains all of these grids. Can do this once and for all on first run. Seems likely to
% be a good idea. Will only use a little extra memory, and will save a lot
% function calls so reduce run time (although probably not by much).
% Will also allow me to then to do the usual checks on grid sizes.
daz_gridstructure=struct();
for jj=1:N_j
    % First, get the sizes of the grids for this age.
    if options.agedependentgrids(1)==1
        n_d_j=n_d(:,jj);
        d_gridParamsCell=num2cell(CreateVectorFromParams(Parameters, AgeDependentGridParamNames.d_grid,jj)'); 
        d_grid_j=d_gridfn(d_gridParamsCell{:});
    else % If not dependent on age
        n_d_j=n_d;
        d_grid_j=d_grid;
    end
    if options.agedependentgrids(2)==1
        n_a_j=n_a(:,jj);
        a_gridParamsCell=num2cell(CreateVectorFromParams(Parameters, AgeDependentGridParamNames.a_grid,jj)');        
        a_grid_j=a_gridfn(a_gridParamsCell{:});
    else % If not dependent on age
        n_a_j=n_a;
        a_grid_j=a_grid;
    end
    if options.agedependentgrids(3)==1
        n_z_j=n_z(:,jj);
        z_gridParamsCell=num2cell(CreateVectorFromParams(Parameters, AgeDependentGridParamNames.z_grid,jj)');        
        [z_grid_j,pi_z_j]=z_gridfn(z_gridParamsCell{:});
    else % If not dependent on age
        n_z_j=n_z;
        z_grid_j=z_grid;
    end
    
    % Following need to be dependent on age.
    N_d_j=prod(n_d_j);
    N_a_j=prod(n_a_j);
    N_z_j=prod(n_z_j);

    N_z_jplus1=prod(n_z(:,min(jj+1,N_j))); % Case of jj==N_j is anyway treated seperately
    % Check the sizes of some of the inputs
    if size(d_grid_j)~=[N_d_j, 1]
        fprintf(['ERROR: d_grid is not the correct shape for age j=',num2str(jj),' (should be of size N_d-by-1)'])
        dbstack
        return
    elseif size(a_grid_j)~=[N_a_j, 1]
        fprintf(['ERROR: a_grid is not the correct shape for age j=',num2str(jj),' (should be of size N_a-by-1)'])
        dbstack
        return
    elseif size(z_grid_j)~=[N_z_j, 1]
        fprintf(['ERROR: z_grid is not the correct shape for age j=',num2str(jj),' (should be of size N_z-by-1)'])
        dbstack
        return
    elseif size(pi_z_j)~=[N_z_j, N_z_jplus1]
        if jj==N_j
            if options.dynasty==0
                %do nothing as pi_z is irrelevant for case of jj==N_j
            else
                if size(pi_z_j)~=[N_z_j, prod(n_z_j(:,1))]
                    fprintf(['ERROR: pi_z is not of size N_z_j-by-N_z_jplus1  for age j=',num2str(jj)'])
                    dbstack
                    return
                end
            end
        else
            fprintf(['ERROR: pi_z is not of size N_z_j-by-N_z_jplus1  for age j=',num2str(jj)'])
            size(pi_z_j)
            [N_z_j, N_z_jplus1]
            dbstack
            return
        end
    end
    
    % Make a three digit number out of jj
    if jj<10
        jstr=['j00',num2str(jj)];
    elseif jj>=10 && jj<100
        jstr=['j0',num2str(jj)];
    else
        jstr=['j',num2str(jj)];
    end
    
    % Store all the grids (and transition matrices) as a structure
    if options.parallel==2
        % If using GPU make sure all the relevant inputs are GPU arrays (not standard arrays)
        pi_z_j=gpuArray(pi_z_j);
        d_grid_j=gpuArray(d_grid_j);
        a_grid_j=gpuArray(a_grid_j);
        z_grid_j=gpuArray(z_grid_j);
        % else
        %    % If using CPU make sure all the relevant inputs are CPU arrays (not standard arrays)
        %    % This may be completely unnecessary.
        %    pi_z_j=gather(pi_z_j);
        %    d_grid_j=gather(d_grid_j);
        %    a_grid_j=gather(a_grid_j);
        %    z_grid_j=gather(z_grid_j);
    end
    daz_gridstructure.d_grid.(jstr(:))=d_grid_j;
    daz_gridstructure.a_grid.(jstr(:))=a_grid_j;
    daz_gridstructure.z_grid.(jstr(:))=z_grid_j;
    daz_gridstructure.pi_z.(jstr(:))=pi_z_j;
    daz_gridstructure.N_d.(jstr(:))=N_d_j;
    daz_gridstructure.n_d.(jstr(:))=n_d_j;
    daz_gridstructure.N_a.(jstr(:))=N_a_j;
    daz_gridstructure.n_a.(jstr(:))=n_a_j;
    daz_gridstructure.N_z.(jstr(:))=N_z_j;
    daz_gridstructure.n_z.(jstr(:))=n_z_j;

    % Makes future coding easier if I also store zprime, even though in principle it is redundant.
    % Make a three digit number out of jj-1
    jjminus1=jj-1;
    if jjminus1==0
        jjminus1=N_j;
    end
    if jjminus1<10
        jminus1str=['j00',num2str(jjminus1)];
    elseif minus1>=10 && jjminus1<100
        jminus1str=['j0',num2str(jjminus1)];
    else
        jminus1str=['j',num2str(jjminus1)];
    end
    daz_gridstructure.N_aprime.(jminus1str(:))=N_a_j;
    daz_gridstructure.N_zprime.(jminus1str(:))=N_z_j;
    daz_gridstructure.n_zprime.(jminus1str(:))=n_z_j;
    daz_gridstructure.zprime_grid.(jminus1str(:))=z_grid_j;
end


end