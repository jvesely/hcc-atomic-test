
MAIN_SRCS= \
	cmp-swap.cpp \
	interference.cpp \
	load.cpp \
	store.cpp \
	swap.cpp \
	global.cpp

AUX_SRCS= \

BINS=$(addprefix atomic-, $(subst .cpp,,$(MAIN_SRCS)))

SRCS=$(MAIN_SRCS) $(AUX_SRCS)
OBJS=$(SRCS:.cpp=.o)
DEPS=$(SRCS:.cpp=.d)

HCC_CONFIG=/opt/rocm/hcc-amdgpu/bin/hcc-config
CXX=/opt/rocm/hcc-amdgpu/bin/clang++

#hcc-config mixes compiler and preprocessor flags
HCC_CPPFLAGS=$(shell $(HCC_CONFIG) --cxxflags --install)
HCC_CXXFLAGS=$(shell $(HCC_CONFIG) --cxxflags --install)
HCC_LDFLAGS=$(shell $(HCC_CONFIG) --ldflags --install)

CPP_FLAGS=$(HCC_CPPFLAGS)
CXX_FLAGS=$(HCC_CXXFLAGS)
LD_FLAGS=$(HCC_LDFLAGS)

all: $(BINS)

atomic-% : %.o
	$(CXX) $^ -o $@ $(LD_FLAGS)

%.o: %.cpp
	$(CXX) -c $< $(CPP_FLAGS) $(CXX_FLAGS) -o $@

%.d: %.cpp
	$(CXX) -MMD -MF $@ $(CPP_FLAGS) $< -E > /dev/null

-include $(DEPS)

clean:
	rm -vf $(OBJS) $(BINS) $(DEPS)
