import { useState, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { api } from '@/api/client';
import { Plus, Pencil, Trash2 } from 'lucide-react';
import {
  FormModal,
  EditFormModal,
  TextInput,
  Textarea,
  SelectInput,
} from '@/components/ui';

interface Team {
  id: number;
  name: string;
  slug: string;
  description?: string | null;
  color?: string | null;
}

interface TeamStats {
  task_count: number;
  task_type_count: number;
  is_unassigned_team: boolean;
}

export function TeamsSettings() {
  const queryClient = useQueryClient();
  
  // Modal states
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [editingTeam, setEditingTeam] = useState<Team | null>(null);
  const [deleteTeam, setDeleteTeam] = useState<Team | null>(null);
  const [teamStats, setTeamStats] = useState<TeamStats | null>(null);
  const [taskAction, setTaskAction] = useState<'reassign' | 'delete'>('reassign');
  const [reassignTo, setReassignTo] = useState<number | undefined>(undefined);

  // Create form state
  const [createName, setCreateName] = useState('');
  const [createSlug, setCreateSlug] = useState('');
  const [createDescription, setCreateDescription] = useState('');
  const [createColor, setCreateColor] = useState('#3B82F6');

  // Edit form state
  const [editName, setEditName] = useState('');
  const [editDescription, setEditDescription] = useState('');
  const [editColor, setEditColor] = useState('#3B82F6');

  // Sync edit form when editingTeam changes
  useEffect(() => {
    if (editingTeam) {
      setEditName(editingTeam.name);
      setEditDescription(editingTeam.description || '');
      setEditColor(editingTeam.color || '#3B82F6');
    }
  }, [editingTeam]);

  const { data: teams, isLoading } = useQuery({
    queryKey: ['teams'],
    queryFn: () => api.teams.list(),
  });

  const createMutation = useMutation({
    mutationFn: api.teams.create,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['teams'] });
      handleCloseCreate();
    },
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: number; data: Partial<{ name: string; description: string; color: string }> }) =>
      api.teams.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['teams'] });
      setEditingTeam(null);
    },
  });

  const deleteMutation = useMutation({
    mutationFn: ({ id, reassignTasksTo, deleteTasks }: { id: number; reassignTasksTo?: number; deleteTasks?: boolean }) =>
      api.teams.delete(id, reassignTasksTo, deleteTasks),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['teams'] });
      queryClient.invalidateQueries({ queryKey: ['tasks'] });
      handleCloseDelete();
    },
  });

  // Handlers
  const handleCloseCreate = () => {
    setShowCreateModal(false);
    setCreateName('');
    setCreateSlug('');
    setCreateDescription('');
    setCreateColor('#3B82F6');
  };

  const handleCreateSubmit = () => {
    createMutation.mutate({
      name: createName,
      slug: createSlug,
      description: createDescription || undefined,
      color: createColor || undefined,
    });
  };

  const handleNameChange = (value: string) => {
    setCreateName(value);
    // Auto-generate slug from name
    setCreateSlug(value.toLowerCase().replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, ''));
  };

  const handleEditSubmit = () => {
    if (!editingTeam) return;
    updateMutation.mutate({
      id: editingTeam.id,
      data: {
        name: editName,
        description: editDescription || undefined,
        color: editColor || undefined,
      },
    });
  };

  const handleDeleteClick = async (team: Team) => {
    try {
      const stats = await api.teams.getStats(team.id);
      setTeamStats(stats);
      setDeleteTeam(team);
    } catch (error) {
      console.error('Failed to get team stats:', error);
    }
  };

  const handleCloseDelete = () => {
    setDeleteTeam(null);
    setTeamStats(null);
    setTaskAction('reassign');
    setReassignTo(undefined);
  };

  const handleConfirmDelete = () => {
    if (!deleteTeam) return;
    if (taskAction === 'delete') {
      deleteMutation.mutate({
        id: deleteTeam.id,
        deleteTasks: true,
      });
    } else {
      deleteMutation.mutate({
        id: deleteTeam.id,
        reassignTasksTo: reassignTo,
      });
    }
  };

  if (isLoading) {
    return <div className="animate-pulse h-64 bg-gray-100 dark:bg-gray-800 rounded-xl" />;
  }

  const otherTeams = teams?.items?.filter(t => t.id !== deleteTeam?.id) || [];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h2 className="text-lg font-semibold text-gray-900 dark:text-white">Teams</h2>
        <button
          onClick={() => setShowCreateModal(true)}
          className="inline-flex items-center px-3 py-1.5 bg-primary-600 text-white text-sm rounded-lg hover:bg-primary-700"
        >
          <Plus className="h-4 w-4 mr-1" />
          Add Team
        </button>
      </div>

      {/* Teams Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {teams?.items?.map((team) => (
          <div
            key={team.id}
            className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-4"
          >
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div
                  className="w-4 h-4 rounded-full flex-shrink-0"
                  style={{ backgroundColor: team.color || '#9CA3AF' }}
                />
                <div>
                  <h3 className="font-medium text-gray-900 dark:text-white">{team.name}</h3>
                  <p className="text-sm text-gray-500 dark:text-gray-400">@{team.slug}</p>
                </div>
              </div>
              <div className="flex items-center gap-2">
                <button
                  onClick={() => setEditingTeam(team)}
                  className="p-1 text-gray-400 hover:text-gray-600"
                >
                  <Pencil className="h-4 w-4" />
                </button>
                {team.slug !== 'unassigned' && (
                  <button
                    onClick={() => handleDeleteClick(team)}
                    className="p-1 text-red-400 hover:text-red-600"
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                )}
              </div>
            </div>
            {team.description && (
              <p className="mt-2 text-sm text-gray-600 dark:text-gray-400">{team.description}</p>
            )}
          </div>
        ))}
      </div>

      {/* Create Team Modal */}
      <FormModal
        isOpen={showCreateModal}
        onClose={handleCloseCreate}
        onSubmit={handleCreateSubmit}
        title="Add Team"
        submitLabel="Create"
        loadingLabel="Creating..."
        isLoading={createMutation.isPending}
      >
        <div className="space-y-4">
          <TextInput
            label="Name"
            required
            value={createName}
            onChange={(e) => handleNameChange(e.target.value)}
            placeholder="Engineering"
          />
          <TextInput
            label="Slug"
            required
            pattern="[a-z0-9-]+"
            value={createSlug}
            onChange={(e) => setCreateSlug(e.target.value)}
            placeholder="engineering"
          />
          <Textarea
            label="Description"
            value={createDescription}
            onChange={(e) => setCreateDescription(e.target.value)}
            rows={2}
            placeholder="Team description..."
          />
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              Team Color
            </label>
            <div className="flex items-center gap-3">
              <input
                type="color"
                value={createColor}
                onChange={(e) => setCreateColor(e.target.value)}
                className="w-10 h-10 rounded-lg border border-gray-300 dark:border-gray-600 cursor-pointer bg-transparent p-1"
              />
              <input
                type="text"
                value={createColor}
                onChange={(e) => setCreateColor(e.target.value)}
                pattern="^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$"
                className="flex-1 px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white text-sm font-mono"
                placeholder="#3B82F6"
              />
            </div>
          </div>
        </div>
      </FormModal>

      {/* Edit Team Modal */}
      <EditFormModal
        isOpen={!!editingTeam}
        onClose={() => setEditingTeam(null)}
        onSubmit={handleEditSubmit}
        title="Edit Team"
        isLoading={updateMutation.isPending}
      >
        <div className="space-y-4">
          <TextInput
            label="Name"
            required
            value={editName}
            onChange={(e) => setEditName(e.target.value)}
          />
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              Slug
            </label>
            <input
              type="text"
              disabled
              value={editingTeam?.slug || ''}
              className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-gray-100 dark:bg-gray-600 text-gray-500"
            />
            <p className="text-xs text-gray-500 mt-1">Slug cannot be changed</p>
          </div>
          <Textarea
            label="Description"
            value={editDescription}
            onChange={(e) => setEditDescription(e.target.value)}
            rows={2}
          />
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              Team Color
            </label>
            <div className="flex items-center gap-3">
              <input
                type="color"
                value={editColor}
                onChange={(e) => setEditColor(e.target.value)}
                className="w-10 h-10 rounded-lg border border-gray-300 dark:border-gray-600 cursor-pointer bg-transparent p-1"
              />
              <input
                type="text"
                value={editColor}
                onChange={(e) => setEditColor(e.target.value)}
                pattern="^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$"
                className="flex-1 px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white text-sm font-mono"
                placeholder="#3B82F6"
              />
            </div>
          </div>
        </div>
      </EditFormModal>

      {/* Delete Team Modal - uses FormModal since it needs custom content */}
      <FormModal
        isOpen={!!deleteTeam && !!teamStats}
        onClose={handleCloseDelete}
        onSubmit={handleConfirmDelete}
        title="Delete Team"
        submitLabel="Delete"
        loadingLabel="Deleting..."
        isLoading={deleteMutation.isPending}
      >
        {deleteTeam && teamStats && (
          <div className="space-y-4">
            <div className="p-3 bg-red-50 dark:bg-red-900/20 rounded-lg">
              <p className="text-sm text-red-800 dark:text-red-200">
                Are you sure you want to delete <strong>{deleteTeam.name}</strong>?
              </p>
            </div>

            {teamStats.task_count > 0 && (
              <div className="space-y-4">
                <p className="text-sm text-gray-600 dark:text-gray-400">
                  This team has <strong>{teamStats.task_count} tasks</strong> and{' '}
                  <strong>{teamStats.task_type_count} task types</strong>.
                </p>
                
                {/* Task Action Options */}
                <div className="space-y-2">
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300">
                    What should happen to the tasks?
                  </label>
                  <div className="space-y-2">
                    <label className="flex items-center gap-2 cursor-pointer">
                      <input
                        type="radio"
                        name="taskAction"
                        value="reassign"
                        checked={taskAction === 'reassign'}
                        onChange={() => setTaskAction('reassign')}
                        className="text-primary-600 focus:ring-primary-500"
                      />
                      <span className="text-sm text-gray-700 dark:text-gray-300">
                        Move tasks to another team
                      </span>
                    </label>
                    <label className="flex items-center gap-2 cursor-pointer">
                      <input
                        type="radio"
                        name="taskAction"
                        value="delete"
                        checked={taskAction === 'delete'}
                        onChange={() => setTaskAction('delete')}
                        className="text-red-600 focus:ring-red-500"
                      />
                      <span className="text-sm text-red-600 dark:text-red-400">
                        Delete all tasks permanently
                      </span>
                    </label>
                  </div>
                </div>
                
                {/* Reassignment Target (only shown when reassign is selected) */}
                {taskAction === 'reassign' && (
                  <div>
                    <SelectInput
                      label="Move tasks to"
                      value={reassignTo?.toString() || ''}
                      onChange={(e) => setReassignTo(e.target.value ? Number(e.target.value) : undefined)}
                      options={[
                        { value: '', label: 'Unassigned Team (default)' },
                        ...otherTeams.map((t) => ({ value: t.id.toString(), label: t.name })),
                      ]}
                    />
                    <p className="text-xs text-gray-500 mt-1">
                      Task types will be deleted. Tasks will be migrated to the target team's default task type.
                    </p>
                  </div>
                )}
                
                {/* Delete Warning */}
                {taskAction === 'delete' && (
                  <div className="p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg">
                    <p className="text-sm text-red-800 dark:text-red-200">
                      ⚠️ <strong>Warning:</strong> This will permanently delete all {teamStats.task_count} tasks and cannot be undone.
                    </p>
                  </div>
                )}
              </div>
            )}
          </div>
        )}
      </FormModal>
    </div>
  );
}
