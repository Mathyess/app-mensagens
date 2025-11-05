-- Adicionar nova coluna para deletar mensagem para todos
-- Execute este script no SQL Editor do Supabase

-- 1. Adicionar coluna is_deleted_for_everyone na tabela messages
ALTER TABLE messages 
ADD COLUMN IF NOT EXISTS is_deleted_for_everyone BOOLEAN DEFAULT FALSE;

-- 2. Criar índice para melhor performance
CREATE INDEX IF NOT EXISTS idx_messages_deleted_for_everyone 
ON messages(is_deleted_for_everyone);

-- 3. Atualizar RLS (Row Level Security) se necessário
-- Verificar se as políticas existentes cobrem a nova coluna

-- 4. Comentário da coluna
COMMENT ON COLUMN messages.is_deleted_for_everyone IS 'Indica se a mensagem foi deletada para todos os participantes da conversa';

-- 5. Verificar se a tabela typing_indicators existe, se não, criar
CREATE TABLE IF NOT EXISTS typing_indicators (
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    is_typing BOOLEAN DEFAULT FALSE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (conversation_id, user_id)
);

-- 6. Habilitar RLS na tabela typing_indicators
ALTER TABLE typing_indicators ENABLE ROW LEVEL SECURITY;

-- 7. Criar políticas para typing_indicators
CREATE POLICY "Users can manage their own typing indicators" ON typing_indicators
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view typing indicators in their conversations" ON typing_indicators
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM conversation_participants cp
            WHERE cp.conversation_id = typing_indicators.conversation_id
            AND cp.user_id = auth.uid()
            AND cp.left_at IS NULL
        )
    );

-- 8. Criar função para limpar indicadores de typing antigos (opcional)
CREATE OR REPLACE FUNCTION cleanup_old_typing_indicators()
RETURNS void AS $$
BEGIN
    DELETE FROM typing_indicators 
    WHERE updated_at < NOW() - INTERVAL '30 seconds';
END;
$$ LANGUAGE plpgsql;

-- 9. Comentários das novas funcionalidades
COMMENT ON TABLE typing_indicators IS 'Tabela para gerenciar indicadores de "digitando" em conversas';
COMMENT ON FUNCTION cleanup_old_typing_indicators() IS 'Função para limpar indicadores de typing antigos automaticamente';