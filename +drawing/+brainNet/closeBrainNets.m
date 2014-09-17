function closeBrainNets(v)
%function closeBrainNet(v)
hasBrainNets = isfield(v, 'brainNets');
if(hasBrainNets)
    numBrainNets = length(v.brainNets);
    for i = 1:numBrainNets
        brainNet = v.brainNets(i);
        
        renderedNodes = brainNet.renderedNodes;
        arrayfun(@(n)(delete(n)), renderedNodes);
        
        renderedEdges = brainNet.renderedEdges;
        %renderedEdges is symmatric around the diagonal, but we don't want
        %to try to remove the same edge twice, invoking delete twice on 
        %same handle throws an error
        edgesBelowDiag = renderedEdges & ~triu(renderedEdges);
        %only remove edges that exist (calling delete(0) will throw error)
        edgesToRemove = edgesBelowDiag(edgesBelowDiag ~= 0);
        arrayfun(@(e)(delete(e)), edgesToRemove);
    end
	v = rmfield(v, 'brainNets');
	guidata(v.hMainFigure, v);
end
