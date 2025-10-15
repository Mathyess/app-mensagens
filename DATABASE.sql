-- =====================================================
-- SCRIPT LIMPO PARA BANCO NOVO
-- App de Mensagens - Supabase
-- =====================================================

-- 1. CRIAR TABELA DE PERFIS
-- =====================================================
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. CRIAR TABELA DE CONVERSAS
-- =====================================================
CREATE TABLE conversations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user1_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  user2_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user1_id, user2_id)
);

-- 3. CRIAR TABELA DE MENSAGENS
-- =====================================================
CREATE TABLE messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE NOT NULL,
  sender_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  content TEXT NOT NULL,
  image_url TEXT,
  is_favorite BOOLEAN DEFAULT FALSE,
  is_archived BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. CRIAR ÍNDICES PARA PERFORMANCE
-- =====================================================
CREATE INDEX idx_profiles_email ON profiles(email);
CREATE INDEX idx_conversations_user1 ON conversations(user1_id);
CREATE INDEX idx_conversations_user2 ON conversations(user2_id);
CREATE INDEX idx_conversations_updated_at ON conversations(updated_at DESC);
CREATE INDEX idx_messages_conversation ON messages(conversation_id);
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_created_at ON messages(created_at DESC);
CREATE INDEX idx_messages_favorite ON messages(is_favorite) WHERE is_favorite = TRUE;
CREATE INDEX idx_messages_archived ON messages(is_archived) WHERE is_archived = TRUE;

-- 5. HABILITAR ROW LEVEL SECURITY (RLS)
-- =====================================================
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- 6. POLÍTICAS DE SEGURANÇA PARA PERFIS
-- =====================================================
CREATE POLICY "Perfis são visíveis para todos" ON profiles 
  FOR SELECT USING (true);

CREATE POLICY "Usuários podem inserir seu próprio perfil" ON profiles 
  FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Usuários podem atualizar seu próprio perfil" ON profiles 
  FOR UPDATE USING (auth.uid() = id);

-- 7. POLÍTICAS DE SEGURANÇA PARA CONVERSAS
-- =====================================================
CREATE POLICY "Usuários podem ver suas conversas" ON conversations 
  FOR SELECT USING (auth.uid() = user1_id OR auth.uid() = user2_id);

CREATE POLICY "Usuários podem criar conversas" ON conversations 
  FOR INSERT WITH CHECK (auth.uid() = user1_id OR auth.uid() = user2_id);

CREATE POLICY "Usuários podem atualizar suas conversas" ON conversations 
  FOR UPDATE USING (auth.uid() = user1_id OR auth.uid() = user2_id);

-- 8. POLÍTICAS DE SEGURANÇA PARA MENSAGENS
-- =====================================================
CREATE POLICY "Usuários podem ver mensagens de suas conversas" ON messages 
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM conversations 
      WHERE conversations.id = messages.conversation_id 
      AND (conversations.user1_id = auth.uid() OR conversations.user2_id = auth.uid())
    )
  );

CREATE POLICY "Usuários autenticados podem inserir mensagens" ON messages 
  FOR INSERT WITH CHECK (
    auth.role() = 'authenticated' 
    AND auth.uid() = sender_id
    AND EXISTS (
      SELECT 1 FROM conversations 
      WHERE conversations.id = messages.conversation_id 
      AND (conversations.user1_id = auth.uid() OR conversations.user2_id = auth.uid())
    )
  );

CREATE POLICY "Usuários podem atualizar suas próprias mensagens" ON messages 
  FOR UPDATE USING (auth.uid() = sender_id);

CREATE POLICY "Usuários podem deletar suas próprias mensagens" ON messages 
  FOR DELETE USING (auth.uid() = sender_id);

-- 9. FUNÇÕES AUXILIARES
-- =====================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 10. TRIGGERS
-- =====================================================
CREATE TRIGGER update_profiles_updated_at 
  BEFORE UPDATE ON profiles 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_conversations_updated_at 
  BEFORE UPDATE ON conversations 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, name, email)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'name', 'Usuário'), NEW.email);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 11. VIEWS ÚTEIS
-- =====================================================
CREATE VIEW user_conversations AS
SELECT 
  c.id as conversation_id,
  c.user1_id,
  c.user2_id,
  c.created_at as conversation_created_at,
  c.updated_at as conversation_updated_at,
  CASE 
    WHEN c.user1_id = auth.uid() THEN c.user2_id 
    ELSE c.user1_id 
  END as other_user_id,
  CASE 
    WHEN c.user1_id = auth.uid() THEN p2.name 
    ELSE p1.name 
  END as other_user_name,
  CASE 
    WHEN c.user1_id = auth.uid() THEN p2.email 
    ELSE p1.email 
  END as other_user_email,
  CASE 
    WHEN c.user1_id = auth.uid() THEN p2.avatar_url 
    ELSE p1.avatar_url 
  END as other_user_avatar,
  m.content as last_message,
  m.created_at as last_message_at,
  m.sender_id as last_message_sender_id
FROM conversations c
LEFT JOIN profiles p1 ON c.user1_id = p1.id
LEFT JOIN profiles p2 ON c.user2_id = p2.id
LEFT JOIN LATERAL (
  SELECT content, created_at, sender_id
  FROM messages 
  WHERE conversation_id = c.id 
  ORDER BY created_at DESC 
  LIMIT 1
) m ON true
WHERE c.user1_id = auth.uid() OR c.user2_id = auth.uid()
ORDER BY c.updated_at DESC;

-- 12. CONFIGURAÇÕES FINAIS
-- =====================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Comentários nas tabelas
COMMENT ON TABLE profiles IS 'Perfis dos usuários do sistema';
COMMENT ON TABLE conversations IS 'Conversas entre usuários';
COMMENT ON TABLE messages IS 'Mensagens das conversas';

-- Comentários nas colunas importantes
COMMENT ON COLUMN conversations.user1_id IS 'ID do primeiro usuário da conversa';
COMMENT ON COLUMN conversations.user2_id IS 'ID do segundo usuário da conversa';
COMMENT ON COLUMN messages.conversation_id IS 'ID da conversa à qual a mensagem pertence';
COMMENT ON COLUMN messages.sender_id IS 'ID do usuário que enviou a mensagem';

-- =====================================================
-- FIM DO SCRIPT
-- =====================================================
