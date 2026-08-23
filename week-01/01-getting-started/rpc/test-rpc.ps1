$body = @{
    jsonrpc = "2.0"
    id      = 1
    method  = "get_tip_block_number"
    params  = @()
} | ConvertTo-Json

Invoke-RestMethod `
    -Uri "http://127.0.0.1:28114" `
    -Method Post `
    -ContentType "application/json" `
    -Body $body
