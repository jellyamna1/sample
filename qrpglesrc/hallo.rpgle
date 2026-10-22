**free
ctl-opt dftactgrp(*no) actgrp(*caller);

dcl-s reply char(1);

// dengan response field, DSPLY menunggu Enter sebelum program selesai
dsply 'Hallo World' '' reply;

*inlr = *on;
return;
