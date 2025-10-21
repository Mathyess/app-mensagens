-- =====================================================
-- QUERIES ÚTEIS PARA TESTAR E GERENCIAR O SISTEMA
-- App de Mensagens - Supabase
-- =====================================================

-- 1. QUERIES PARA TESTAR O SISTEMA
-- =====================================================

-- Ver todos os perfis
SELECT * FROM profiles ORDER BY created_at DESC;

-- Ver todas as conversas
SELECT * FROM conversations ORDER BY created_at DESC;

-- Ver todas as mensagens
SELECT * FROM messages ORDER BY created_at DESC;

-- Ver conversas de um usuário específico
SELECT * FROM user_conversations WHERE user1_id = 'SEU_USER_ID' OR user2_id = 'SEU_USER_ID';

-- Ver mensagens de uma conversa específica
SELECT 
  m.*,
  p.name as sender_name
FROM messages m
JOIN profiles p ON m.sender_id = p.id
WHERE m.conversation_id = 'CONVERSATION_ID'
ORDER BY m.created_at ASC;

-- 2. QUERIES PARA ESTATÍSTICAS
-- =====================================================

-- Contar total de usuários
SELECT COUNT(*) as total_users FROM profiles;

-- Contar total de conversas
SELECT COUNT(*) as total_conversations FROM conversations;

-- Contar total de mensagens
SELECT COUNT(*) as total_messages FROM messages;

-- Usuários mais ativos (por número de mensagens)
SELECT 
  p.name,
  p.email,
  COUNT(m.id) as message_count
FROM profiles p
LEFT JOIN messages m ON p.id = m.sender_id
GROUP BY p.id, p.name, p.email
ORDER BY message_count DESC;

-- Conversas mais ativas
SELECT 
  c.id,
  p1.name as user1_name,
  p2.name as user2_name,
  COUNT(m.id) as message_count,
  MAX(m.created_at) as last_message_at
FROM conversations c
LEFT JOIN profiles p1 ON c.user1_id = p1.id
LEFT JOIN profiles p2 ON c.user2_id = p2.id
LEFT JOIN messages m ON c.id = m.conversation_id
GROUP BY c.id, p1.name, p2.name
ORDER BY message_count DESC;

-- 3. QUERIES PARA LIMPEZA (CUIDADO!)
-- =====================================================

-- Limpar todas as mensagens (CUIDADO!)
-- DELETE FROM messages;

-- Limpar todas as conversas (CUIDADO!)
-- DELETE FROM conversations;

-- Limpar todos os perfis (CUIDADO!)
-- DELETE FROM profiles;

-- 4. QUERIES PARA MANUTENÇÃO
-- =====================================================

-- Encontrar conversas sem mensagens
SELECT c.*, p1.name as user1_name, p2.name as user2_name
FROM conversations c
LEFT JOIN profiles p1 ON c.user1_id = p1.id
LEFT JOIN profiles p2 ON c.user2_id = p2.id
LEFT JOIN messages m ON c.id = m.conversation_id
WHERE m.id IS NULL;

-- Encontrar mensagens órfãs (sem conversa)
SELECT m.*
FROM messages m
LEFT JOIN conversations c ON m.conversation_id = c.id
WHERE c.id IS NULL;

-- Encontrar perfis sem conversas
SELECT p.*
FROM profiles p
LEFT JOIN conversations c ON (p.id = c.user1_id OR p.id = c.user2_id)
WHERE c.id IS NULL;

-- 5. QUERIES PARA DESENVOLVIMENTO
-- =====================================================

-- Criar conversa entre dois usuários
-- INSERT INTO conversations (user1_id, user2_id) 
-- VALUES ('USER1_ID', 'USER2_ID');

-- Enviar mensagem em uma conversa
-- INSERT INTO messages (conversation_id, sender_id, content) 
-- VALUES ('CONVERSATION_ID', 'SENDER_ID', 'Conteúdo da mensagem');

-- Atualizar perfil de usuário
-- UPDATE profiles 
-- SET name = 'Novo Nome', updated_at = NOW() 
-- WHERE id = 'USER_ID';

-- 6. QUERIES PARA RELATÓRIOS
-- =====================================================

-- Relatório de atividade por dia
SELECT 
  DATE(created_at) as date,
  COUNT(*) as messages_count
FROM messages
GROUP BY DATE(created_at)
ORDER BY date DESC;

-- Relatório de usuários por período de registro
SELECT 
  DATE(created_at) as registration_date,
  COUNT(*) as new_users
FROM profiles
GROUP BY DATE(created_at)
ORDER BY registration_date DESC;

-- Top 10 conversas mais longas
SELECT 
  c.id,
  p1.name as user1_name,
  p2.name as user2_name,
  COUNT(m.id) as message_count,
  MIN(m.created_at) as first_message,
  MAX(m.created_at) as last_message
FROM conversations c
JOIN profiles p1 ON c.user1_id = p1.id
JOIN profiles p2 ON c.user2_id = p2.id
JOIN messages m ON c.id = m.conversation_id
GROUP BY c.id, p1.name, p2.name
ORDER BY message_count DESC
LIMIT 10;

-- 7. QUERIES PARA BACKUP E RESTAURAÇÃO
-- =====================================================

-- Exportar dados de perfis
-- COPY profiles TO '/path/to/profiles_backup.csv' WITH CSV HEADER;

-- Exportar dados de conversas
-- COPY conversations TO '/path/to/conversations_backup.csv' WITH CSV HEADER;

-- Exportar dados de mensagens
-- COPY messages TO '/path/to/messages_backup.csv' WITH CSV HEADER;

-- 8. QUERIES PARA MONITORAMENTO
-- =====================================================

-- Verificar integridade dos dados
SELECT 
  'profiles' as table_name,
  COUNT(*) as total_records,
  COUNT(DISTINCT id) as unique_ids,
  COUNT(*) - COUNT(DISTINCT id) as duplicates
FROM profiles
UNION ALL
SELECT 
  'conversations' as table_name,
  COUNT(*) as total_records,
  COUNT(DISTINCT id) as unique_ids,
  COUNT(*) - COUNT(DISTINCT id) as duplicates
FROM conversations
UNION ALL
SELECT 
  'messages' as table_name,
  COUNT(*) as total_records,
  COUNT(DISTINCT id) as unique_ids,
  COUNT(*) - COUNT(DISTINCT id) as duplicates
FROM messages;

-- Verificar referências quebradas
SELECT 
  'messages without valid conversation' as issue,
  COUNT(*) as count
FROM messages m
LEFT JOIN conversations c ON m.conversation_id = c.id
WHERE c.id IS NULL
UNION ALL
SELECT 
  'messages without valid sender' as issue,
  COUNT(*) as count
FROM messages m
LEFT JOIN profiles p ON m.sender_id = p.id
WHERE p.id IS NULL;

-- =====================================================
-- FIM DAS QUERIES ÚTEIS
-- =====================================================

