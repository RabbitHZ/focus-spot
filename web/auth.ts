import NextAuth from "next-auth";
import Google from "next-auth/providers/google";

export const { handlers, signIn, signOut, auth } = NextAuth({
  providers: [
    Google({
      clientId: process.env.GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
    }),
  ],
  callbacks: {
    async jwt({ token, account }) {
      if (account?.id_token) {
        token.id_token = account.id_token;
        // Google id_token은 1시간 후 만료 — 만료 시각을 함께 저장
        token.id_token_expires_at = Date.now() + 55 * 60 * 1000;
      }
      return token;
    },
    async session({ session, token }) {
      // id_token이 만료됐으면 세션에 포함하지 않아 프론트가 재로그인 유도
      const expiresAt = token.id_token_expires_at as number | undefined;
      if (token.id_token && expiresAt && Date.now() < expiresAt) {
        session.id_token = token.id_token as string;
      } else {
        session.id_token = undefined;
      }
      if (session.user) {
        session.user.image = (token.picture as string) ?? session.user.image;
      }
      return session;
    },
  },
});
