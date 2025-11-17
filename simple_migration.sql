-- Adicionar coluna is_deleted_for_everyone na tabela messages
ALTER TABLE messages 
ADD COLUMN IF NOT EXISTS is_deleted_for_everyone BOOLEAN DEFAULT FALSE;

-- Criar índice para melhor performance
CREATE INDEX IF NOT EXISTS idx_messages_deleted_for_everyone 
ON messages(is_deleted_for_everyone);