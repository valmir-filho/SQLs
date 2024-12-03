SELECT 'O dispositivo número ' || D.CODDSP || ' da unidade ' || D.DESDSP || 
       ' está sem registros no dia ' || TO_CHAR(SYSDATE, 'dd/mm/yyyy') || '.' || chr(13) || chr(10) AS msg
FROM R058DSP D
WHERE D.CODDSP IN
(
  22, 36, 44, 50, 53, 55, 57, 58, 59, 74, 78, 82, 84, 86, 88, 94, 97, 99, 101, 105,
  108, 110, 112, 114, 128, 130, 132, 135, 136, 149, 165, 170, 172, 175, 180, 182, 185, 187, 189, 192
)
AND D.CODDSP NOT IN (
  SELECT CODDSP
  FROM R070ACC
  WHERE TRUNC(DATAPU) = TRUNC(SYSDATE)
)
AND TO_CHAR(SYSDATE, 'D') NOT IN (7, 1);  -- Ignora finais de semana.
