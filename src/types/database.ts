export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[];

export type Database = {
  public: {
    Tables: {
      briefs: {
        Row: {
          attachments: string[];
          budget_max_paise: number | null;
          budget_min_paise: number | null;
          category_id: number | null;
          created_at: string;
          founder_id: string;
          id: string;
          needs_formulation: boolean;
          product_type: string | null;
          required_cert_ids: number[];
          specs: NonNullable<Json>;
          status: Database['public']['Enums']['brief_status'];
          target_qty: number | null;
          timeline: Database['public']['Enums']['brief_timeline'] | null;
          title: string | null;
          updated_at: string;
        };
        Insert: {
          attachments?: string[];
          budget_max_paise?: number | null;
          budget_min_paise?: number | null;
          category_id?: number | null;
          created_at?: string;
          founder_id?: string;
          id?: string;
          needs_formulation?: boolean;
          product_type?: string | null;
          required_cert_ids?: number[];
          specs?: NonNullable<Json>;
          status?: Database['public']['Enums']['brief_status'];
          target_qty?: number | null;
          timeline?: Database['public']['Enums']['brief_timeline'] | null;
          title?: string | null;
          updated_at?: string;
        };
        Update: {
          attachments?: string[];
          budget_max_paise?: number | null;
          budget_min_paise?: number | null;
          category_id?: number | null;
          created_at?: string;
          founder_id?: string;
          id?: string;
          needs_formulation?: boolean;
          product_type?: string | null;
          required_cert_ids?: number[];
          specs?: NonNullable<Json>;
          status?: Database['public']['Enums']['brief_status'];
          target_qty?: number | null;
          timeline?: Database['public']['Enums']['brief_timeline'] | null;
          title?: string | null;
          updated_at?: string;
        };
        Relationships: [
          {
            foreignKeyName: 'briefs_category_id_fkey';
            columns: ['category_id'];
            isOneToOne: false;
            referencedRelation: 'categories';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'briefs_founder_id_fkey';
            columns: ['founder_id'];
            isOneToOne: false;
            referencedRelation: 'users';
            referencedColumns: ['id'];
          },
        ];
      };
      categories: {
        Row: {
          created_at: string;
          id: number;
          name: string;
          name_hi: string | null;
          parent_id: number | null;
          slug: string;
          sort_order: number;
        };
        Insert: {
          created_at?: string;
          id?: never;
          name: string;
          name_hi?: string | null;
          parent_id?: number | null;
          slug: string;
          sort_order?: number;
        };
        Update: {
          created_at?: string;
          id?: never;
          name?: string;
          name_hi?: string | null;
          parent_id?: number | null;
          slug?: string;
          sort_order?: number;
        };
        Relationships: [
          {
            foreignKeyName: 'categories_parent_id_fkey';
            columns: ['parent_id'];
            isOneToOne: false;
            referencedRelation: 'categories';
            referencedColumns: ['id'];
          },
        ];
      };
      certifications: {
        Row: {
          code: string;
          created_at: string;
          description: string | null;
          id: number;
          name: string;
        };
        Insert: {
          code: string;
          created_at?: string;
          description?: string | null;
          id?: never;
          name: string;
        };
        Update: {
          code?: string;
          created_at?: string;
          description?: string | null;
          id?: never;
          name?: string;
        };
        Relationships: [];
      };
      founder_profiles: {
        Row: {
          city: string;
          company_name: string;
          created_at: string;
          gstin: string | null;
          stage: Database['public']['Enums']['founder_stage'];
          state: string;
          updated_at: string;
          user_id: string;
        };
        Insert: {
          city: string;
          company_name: string;
          created_at?: string;
          gstin?: string | null;
          stage?: Database['public']['Enums']['founder_stage'];
          state: string;
          updated_at?: string;
          user_id: string;
        };
        Update: {
          city?: string;
          company_name?: string;
          created_at?: string;
          gstin?: string | null;
          stage?: Database['public']['Enums']['founder_stage'];
          state?: string;
          updated_at?: string;
          user_id?: string;
        };
        Relationships: [
          {
            foreignKeyName: 'founder_profiles_state_fkey';
            columns: ['state'];
            isOneToOne: false;
            referencedRelation: 'indian_states';
            referencedColumns: ['code'];
          },
          {
            foreignKeyName: 'founder_profiles_user_id_fkey';
            columns: ['user_id'];
            isOneToOne: true;
            referencedRelation: 'users';
            referencedColumns: ['id'];
          },
        ];
      };
      indian_states: {
        Row: {
          code: string;
          gst_code: string;
          is_union_territory: boolean;
          name: string;
        };
        Insert: {
          code: string;
          gst_code: string;
          is_union_territory?: boolean;
          name: string;
        };
        Update: {
          code?: string;
          gst_code?: string;
          is_union_territory?: boolean;
          name?: string;
        };
        Relationships: [];
      };
      manufacturer_capabilities: {
        Row: {
          category_id: number;
          formats: string[];
          manufacturer_id: string;
          packaging_types: string[];
        };
        Insert: {
          category_id: number;
          formats?: string[];
          manufacturer_id: string;
          packaging_types?: string[];
        };
        Update: {
          category_id?: number;
          formats?: string[];
          manufacturer_id?: string;
          packaging_types?: string[];
        };
        Relationships: [
          {
            foreignKeyName: 'manufacturer_capabilities_category_id_fkey';
            columns: ['category_id'];
            isOneToOne: false;
            referencedRelation: 'categories';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'manufacturer_capabilities_manufacturer_id_fkey';
            columns: ['manufacturer_id'];
            isOneToOne: false;
            referencedRelation: 'manufacturers';
            referencedColumns: ['id'];
          },
        ];
      };
      manufacturer_certifications: {
        Row: {
          certification_id: number;
          created_at: string;
          document_path: string | null;
          expires_on: string | null;
          licence_no: string | null;
          manufacturer_id: string;
        };
        Insert: {
          certification_id: number;
          created_at?: string;
          document_path?: string | null;
          expires_on?: string | null;
          licence_no?: string | null;
          manufacturer_id: string;
        };
        Update: {
          certification_id?: number;
          created_at?: string;
          document_path?: string | null;
          expires_on?: string | null;
          licence_no?: string | null;
          manufacturer_id?: string;
        };
        Relationships: [
          {
            foreignKeyName: 'manufacturer_certifications_certification_id_fkey';
            columns: ['certification_id'];
            isOneToOne: false;
            referencedRelation: 'certifications';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'manufacturer_certifications_manufacturer_id_fkey';
            columns: ['manufacturer_id'];
            isOneToOne: false;
            referencedRelation: 'manufacturers';
            referencedColumns: ['id'];
          },
        ];
      };
      manufacturer_members: {
        Row: {
          created_at: string;
          manufacturer_id: string;
          role: Database['public']['Enums']['member_role'];
          user_id: string;
        };
        Insert: {
          created_at?: string;
          manufacturer_id: string;
          role?: Database['public']['Enums']['member_role'];
          user_id: string;
        };
        Update: {
          created_at?: string;
          manufacturer_id?: string;
          role?: Database['public']['Enums']['member_role'];
          user_id?: string;
        };
        Relationships: [
          {
            foreignKeyName: 'manufacturer_members_manufacturer_id_fkey';
            columns: ['manufacturer_id'];
            isOneToOne: false;
            referencedRelation: 'manufacturers';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'manufacturer_members_user_id_fkey';
            columns: ['user_id'];
            isOneToOne: true;
            referencedRelation: 'users';
            referencedColumns: ['id'];
          },
        ];
      };
      manufacturers: {
        Row: {
          about: string | null;
          city: string;
          created_at: string;
          created_by: string | null;
          gstin: string;
          id: string;
          legal_name: string;
          median_reply_hours: number | null;
          min_order_qty: number;
          monthly_capacity: number;
          offers_formulation: boolean;
          photo_paths: string[];
          pincode: string;
          rejection_reason: string | null;
          response_rate: number | null;
          sample_policy: Database['public']['Enums']['sample_policy'];
          state: string;
          status: Database['public']['Enums']['manufacturer_status'];
          updated_at: string;
          verified_at: string | null;
          verified_by: string | null;
        };
        Insert: {
          about?: string | null;
          city: string;
          created_at?: string;
          created_by?: string | null;
          gstin: string;
          id?: string;
          legal_name: string;
          median_reply_hours?: number | null;
          min_order_qty: number;
          monthly_capacity: number;
          offers_formulation?: boolean;
          photo_paths?: string[];
          pincode: string;
          rejection_reason?: string | null;
          response_rate?: number | null;
          sample_policy?: Database['public']['Enums']['sample_policy'];
          state: string;
          status?: Database['public']['Enums']['manufacturer_status'];
          updated_at?: string;
          verified_at?: string | null;
          verified_by?: string | null;
        };
        Update: {
          about?: string | null;
          city?: string;
          created_at?: string;
          created_by?: string | null;
          gstin?: string;
          id?: string;
          legal_name?: string;
          median_reply_hours?: number | null;
          min_order_qty?: number;
          monthly_capacity?: number;
          offers_formulation?: boolean;
          photo_paths?: string[];
          pincode?: string;
          rejection_reason?: string | null;
          response_rate?: number | null;
          sample_policy?: Database['public']['Enums']['sample_policy'];
          state?: string;
          status?: Database['public']['Enums']['manufacturer_status'];
          updated_at?: string;
          verified_at?: string | null;
          verified_by?: string | null;
        };
        Relationships: [
          {
            foreignKeyName: 'manufacturers_created_by_fkey';
            columns: ['created_by'];
            isOneToOne: false;
            referencedRelation: 'users';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'manufacturers_state_fkey';
            columns: ['state'];
            isOneToOne: false;
            referencedRelation: 'indian_states';
            referencedColumns: ['code'];
          },
          {
            foreignKeyName: 'manufacturers_verified_by_fkey';
            columns: ['verified_by'];
            isOneToOne: false;
            referencedRelation: 'users';
            referencedColumns: ['id'];
          },
        ];
      };
      match_weights: {
        Row: {
          description: string;
          factor: string;
          updated_at: string;
          weight: number;
        };
        Insert: {
          description: string;
          factor: string;
          updated_at?: string;
          weight: number;
        };
        Update: {
          description?: string;
          factor?: string;
          updated_at?: string;
          weight?: number;
        };
        Relationships: [];
      };
      messages: {
        Row: {
          attachments: string[];
          body: string | null;
          created_at: string;
          id: string;
          outreach_id: string;
          sender_id: string | null;
        };
        Insert: {
          attachments?: string[];
          body?: string | null;
          created_at?: string;
          id?: string;
          outreach_id: string;
          sender_id?: string | null;
        };
        Update: {
          attachments?: string[];
          body?: string | null;
          created_at?: string;
          id?: string;
          outreach_id?: string;
          sender_id?: string | null;
        };
        Relationships: [
          {
            foreignKeyName: 'messages_outreach_id_fkey';
            columns: ['outreach_id'];
            isOneToOne: false;
            referencedRelation: 'outreach';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'messages_sender_id_fkey';
            columns: ['sender_id'];
            isOneToOne: false;
            referencedRelation: 'users';
            referencedColumns: ['id'];
          },
        ];
      };
      outreach: {
        Row: {
          brief_id: string;
          decline_reason: string | null;
          id: string;
          manufacturer_id: string;
          match_reason: string | null;
          match_score: number | null;
          nda_accepted_at: string | null;
          nda_accepted_by: string | null;
          nda_version: string | null;
          responded_at: string | null;
          sent_at: string;
          status: Database['public']['Enums']['outreach_status'];
          updated_at: string;
        };
        Insert: {
          brief_id: string;
          decline_reason?: string | null;
          id?: string;
          manufacturer_id: string;
          match_reason?: string | null;
          match_score?: number | null;
          nda_accepted_at?: string | null;
          nda_accepted_by?: string | null;
          nda_version?: string | null;
          responded_at?: string | null;
          sent_at?: string;
          status?: Database['public']['Enums']['outreach_status'];
          updated_at?: string;
        };
        Update: {
          brief_id?: string;
          decline_reason?: string | null;
          id?: string;
          manufacturer_id?: string;
          match_reason?: string | null;
          match_score?: number | null;
          nda_accepted_at?: string | null;
          nda_accepted_by?: string | null;
          nda_version?: string | null;
          responded_at?: string | null;
          sent_at?: string;
          status?: Database['public']['Enums']['outreach_status'];
          updated_at?: string;
        };
        Relationships: [
          {
            foreignKeyName: 'outreach_brief_id_fkey';
            columns: ['brief_id'];
            isOneToOne: false;
            referencedRelation: 'brief_previews';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'outreach_brief_id_fkey';
            columns: ['brief_id'];
            isOneToOne: false;
            referencedRelation: 'briefs';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'outreach_manufacturer_id_fkey';
            columns: ['manufacturer_id'];
            isOneToOne: false;
            referencedRelation: 'manufacturers';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'outreach_nda_accepted_by_fkey';
            columns: ['nda_accepted_by'];
            isOneToOne: false;
            referencedRelation: 'users';
            referencedColumns: ['id'];
          },
        ];
      };
      quotes: {
        Row: {
          created_at: string;
          created_by: string | null;
          id: string;
          lead_time_days: number;
          moq: number;
          notes: string | null;
          outreach_id: string;
          unit_price_paise: number;
          valid_until: string;
        };
        Insert: {
          created_at?: string;
          created_by?: string | null;
          id?: string;
          lead_time_days: number;
          moq: number;
          notes?: string | null;
          outreach_id: string;
          unit_price_paise: number;
          valid_until: string;
        };
        Update: {
          created_at?: string;
          created_by?: string | null;
          id?: string;
          lead_time_days?: number;
          moq?: number;
          notes?: string | null;
          outreach_id?: string;
          unit_price_paise?: number;
          valid_until?: string;
        };
        Relationships: [
          {
            foreignKeyName: 'quotes_created_by_fkey';
            columns: ['created_by'];
            isOneToOne: false;
            referencedRelation: 'users';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'quotes_outreach_id_fkey';
            columns: ['outreach_id'];
            isOneToOne: false;
            referencedRelation: 'outreach';
            referencedColumns: ['id'];
          },
        ];
      };
      reports: {
        Row: {
          created_at: string;
          details: string | null;
          id: string;
          manufacturer_id: string | null;
          outreach_id: string | null;
          reason: Database['public']['Enums']['report_reason'];
          reported_user_id: string | null;
          reporter_id: string | null;
          resolution_note: string | null;
          resolved_at: string | null;
          resolved_by: string | null;
          status: Database['public']['Enums']['report_status'];
        };
        Insert: {
          created_at?: string;
          details?: string | null;
          id?: string;
          manufacturer_id?: string | null;
          outreach_id?: string | null;
          reason: Database['public']['Enums']['report_reason'];
          reported_user_id?: string | null;
          reporter_id?: string | null;
          resolution_note?: string | null;
          resolved_at?: string | null;
          resolved_by?: string | null;
          status?: Database['public']['Enums']['report_status'];
        };
        Update: {
          created_at?: string;
          details?: string | null;
          id?: string;
          manufacturer_id?: string | null;
          outreach_id?: string | null;
          reason?: Database['public']['Enums']['report_reason'];
          reported_user_id?: string | null;
          reporter_id?: string | null;
          resolution_note?: string | null;
          resolved_at?: string | null;
          resolved_by?: string | null;
          status?: Database['public']['Enums']['report_status'];
        };
        Relationships: [
          {
            foreignKeyName: 'reports_manufacturer_id_fkey';
            columns: ['manufacturer_id'];
            isOneToOne: false;
            referencedRelation: 'manufacturers';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'reports_outreach_id_fkey';
            columns: ['outreach_id'];
            isOneToOne: false;
            referencedRelation: 'outreach';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'reports_reported_user_id_fkey';
            columns: ['reported_user_id'];
            isOneToOne: false;
            referencedRelation: 'users';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'reports_reporter_id_fkey';
            columns: ['reporter_id'];
            isOneToOne: false;
            referencedRelation: 'users';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'reports_resolved_by_fkey';
            columns: ['resolved_by'];
            isOneToOne: false;
            referencedRelation: 'users';
            referencedColumns: ['id'];
          },
        ];
      };
      samples: {
        Row: {
          created_at: string;
          feedback: string | null;
          id: string;
          outreach_id: string;
          status: Database['public']['Enums']['sample_status'];
          updated_at: string;
        };
        Insert: {
          created_at?: string;
          feedback?: string | null;
          id?: string;
          outreach_id: string;
          status?: Database['public']['Enums']['sample_status'];
          updated_at?: string;
        };
        Update: {
          created_at?: string;
          feedback?: string | null;
          id?: string;
          outreach_id?: string;
          status?: Database['public']['Enums']['sample_status'];
          updated_at?: string;
        };
        Relationships: [
          {
            foreignKeyName: 'samples_outreach_id_fkey';
            columns: ['outreach_id'];
            isOneToOne: false;
            referencedRelation: 'outreach';
            referencedColumns: ['id'];
          },
        ];
      };
      users: {
        Row: {
          created_at: string;
          email: string | null;
          id: string;
          name: string | null;
          phone: string | null;
          role: Database['public']['Enums']['user_role'] | null;
          updated_at: string;
        };
        Insert: {
          created_at?: string;
          email?: string | null;
          id: string;
          name?: string | null;
          phone?: string | null;
          role?: Database['public']['Enums']['user_role'] | null;
          updated_at?: string;
        };
        Update: {
          created_at?: string;
          email?: string | null;
          id?: string;
          name?: string | null;
          phone?: string | null;
          role?: Database['public']['Enums']['user_role'] | null;
          updated_at?: string;
        };
        Relationships: [];
      };
    };
    Views: {
      brief_previews: {
        Row: {
          category_id: number | null;
          created_at: string | null;
          founder_city: string | null;
          founder_state: string | null;
          id: string | null;
          needs_formulation: boolean | null;
          product_type: string | null;
          required_cert_ids: number[] | null;
          status: Database['public']['Enums']['brief_status'] | null;
          target_qty: number | null;
          timeline: Database['public']['Enums']['brief_timeline'] | null;
        };
        Relationships: [
          {
            foreignKeyName: 'briefs_category_id_fkey';
            columns: ['category_id'];
            isOneToOne: false;
            referencedRelation: 'categories';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'founder_profiles_state_fkey';
            columns: ['founder_state'];
            isOneToOne: false;
            referencedRelation: 'indian_states';
            referencedColumns: ['code'];
          },
        ];
      };
    };
    Functions: {
      accept_nda: {
        Args: { p_nda_version?: string; p_outreach_id: string };
        Returns: {
          brief_id: string;
          decline_reason: string | null;
          id: string;
          manufacturer_id: string;
          match_reason: string | null;
          match_score: number | null;
          nda_accepted_at: string | null;
          nda_accepted_by: string | null;
          nda_version: string | null;
          responded_at: string | null;
          sent_at: string;
          status: Database['public']['Enums']['outreach_status'];
          updated_at: string;
        };
        SetofOptions: {
          from: '*';
          to: 'outreach';
          isOneToOne: true;
          isSetofReturn: false;
        };
      };
      is_valid_gstin: { Args: { p_gstin: string }; Returns: boolean };
      set_my_role: {
        Args: { p_role: Database['public']['Enums']['user_role'] };
        Returns: {
          created_at: string;
          email: string | null;
          id: string;
          name: string | null;
          phone: string | null;
          role: Database['public']['Enums']['user_role'] | null;
          updated_at: string;
        };
        SetofOptions: {
          from: '*';
          to: 'users';
          isOneToOne: true;
          isSetofReturn: false;
        };
      };
    };
    Enums: {
      brief_status: 'draft' | 'open' | 'closed';
      brief_timeline: 'within_1_month' | '1_to_3_months' | '3_to_6_months' | 'over_6_months';
      founder_stage: 'idea' | 'launched';
      manufacturer_status: 'pending' | 'verified' | 'rejected' | 'paused';
      member_role: 'owner' | 'sales' | 'rnd';
      outreach_status:
        'sent' | 'nda_signed' | 'accepted' | 'declined' | 'quoted' | 'sampling' | 'ordered';
      report_reason: 'spam' | 'no_show' | 'misleading_profile' | 'abusive' | 'other';
      report_status: 'open' | 'resolved' | 'dismissed';
      sample_policy: 'free' | 'paid' | 'paid_adjusted_on_order' | 'not_offered';
      sample_status: 'requested' | 'sent' | 'received' | 'approved' | 'rejected';
      user_role: 'founder' | 'manufacturer' | 'admin';
    };
    CompositeTypes: {
      [_ in never]: never;
    };
  };
};

type DatabaseWithoutInternals = Omit<Database, '__InternalSupabase'>;

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, 'public'>];

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema['Tables'] & DefaultSchema['Views'])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables'] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Views'])
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables'] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Views'])[TableName] extends {
      Row: infer R;
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema['Tables'] & DefaultSchema['Views'])
    ? (DefaultSchema['Tables'] & DefaultSchema['Views'])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R;
      }
      ? R
      : never
    : never;

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    keyof DefaultSchema['Tables'] | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables']
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables'][TableName] extends {
      Insert: infer I;
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema['Tables']
    ? DefaultSchema['Tables'][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I;
      }
      ? I
      : never
    : never;

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    keyof DefaultSchema['Tables'] | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables']
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables'][TableName] extends {
      Update: infer U;
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema['Tables']
    ? DefaultSchema['Tables'][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U;
      }
      ? U
      : never
    : never;

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    keyof DefaultSchema['Enums'] | { schema: keyof DatabaseWithoutInternals },
  EnumName extends (DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions['schema']]['Enums']
    : never) = never,
> = DefaultSchemaEnumNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions['schema']]['Enums'][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema['Enums']
    ? DefaultSchema['Enums'][DefaultSchemaEnumNameOrOptions]
    : never;

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    keyof DefaultSchema['CompositeTypes'] | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends (PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions['schema']]['CompositeTypes']
    : never) = never,
> = PublicCompositeTypeNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions['schema']]['CompositeTypes'][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema['CompositeTypes']
    ? DefaultSchema['CompositeTypes'][PublicCompositeTypeNameOrOptions]
    : never;

export const Constants = {
  public: {
    Enums: {
      brief_status: ['draft', 'open', 'closed'],
      brief_timeline: ['within_1_month', '1_to_3_months', '3_to_6_months', 'over_6_months'],
      founder_stage: ['idea', 'launched'],
      manufacturer_status: ['pending', 'verified', 'rejected', 'paused'],
      member_role: ['owner', 'sales', 'rnd'],
      outreach_status: [
        'sent',
        'nda_signed',
        'accepted',
        'declined',
        'quoted',
        'sampling',
        'ordered',
      ],
      report_reason: ['spam', 'no_show', 'misleading_profile', 'abusive', 'other'],
      report_status: ['open', 'resolved', 'dismissed'],
      sample_policy: ['free', 'paid', 'paid_adjusted_on_order', 'not_offered'],
      sample_status: ['requested', 'sent', 'received', 'approved', 'rejected'],
      user_role: ['founder', 'manufacturer', 'admin'],
    },
  },
} as const;
